// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include "agora_rtc_engine_plugin.h"

// This must be included before VersionHelpers.h.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/basic_message_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>

#include "IAgoraRtcEngine.h"

using namespace agora::rtc;

namespace {
    using flutter::EncodableMap;
    using flutter::EncodableValue;

    void DebugPrintLine(const std::string& string)
    {
        std::wstring wstring{ string.begin(), string.end() };
        OutputDebugString((wstring + L"\n").c_str());
    }

    class AgoraRtcEnginePlugin : public flutter::Plugin, IRtcEngineEventHandler
    {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

        AgoraRtcEnginePlugin();

        virtual ~AgoraRtcEnginePlugin();

    private:
        // Called when a method is called on this plugin's channel from Dart.
        void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue>& method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

        IRtcEngine* agoraRtcEngine;
    };

    // static
    void AgoraRtcEnginePlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarWindows* registrar)
    {
        auto plugin = std::make_unique<AgoraRtcEnginePlugin>();

        auto channel =
            std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                registrar->messenger(), "agora_rtc_engine",
                &flutter::StandardMethodCodec::GetInstance());

        channel->SetMethodCallHandler(
            [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

        registrar->AddPlugin(std::move(plugin));
    }

    AgoraRtcEnginePlugin::AgoraRtcEnginePlugin() {}

    AgoraRtcEnginePlugin::~AgoraRtcEnginePlugin()
    {
        if (agoraRtcEngine != nullptr)
            agoraRtcEngine->release();
        agoraRtcEngine = nullptr;
    }

    void AgoraRtcEnginePlugin::HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
    {
        auto methodName = method_call.method_name();
        auto params = method_call.arguments()->MapValue();
        DebugPrintLine("plugin HandleMethodCall " + methodName + ", args: " + std::to_string(params.size()));

        if ("create" == methodName)
        {
            auto appId = params[EncodableValue("appId")].StringValue();
            agoraRtcEngine = createAgoraRtcEngine();
            RtcEngineContext ctx;
            ctx.eventHandler = this;
            ctx.appId = appId.c_str();
            agoraRtcEngine->initialize(ctx);
            result->Success(nullptr);
        }
        else
            result->NotImplemented();
    }
}  // namespace

void AgoraRtcEnginePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
    // The plugin registrar wrappers owns the plugins, registered callbacks, etc.,
    // so must remain valid for the life of the application.
    static auto* plugin_registrars =
        new std::map<FlutterDesktopPluginRegistrarRef,
        std::unique_ptr<flutter::PluginRegistrarWindows>>;
    auto insert_result = plugin_registrars->emplace(
        registrar, std::make_unique<flutter::PluginRegistrarWindows>(registrar));

    AgoraRtcEnginePlugin::RegisterWithRegistrar(insert_result.first->second.get());
}
