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
#include <flutter/standard_message_codec.h>
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

#pragma region IRtcEngineEventHandler
    	void onUserJoined(uid_t uid, int elapsed) override;
        void onUserOffline(uid_t uid, USER_OFFLINE_REASON_TYPE reason) override;
        void onRtcStats(const RtcStats& stats) override;
        void onRemoteAudioStats(const RemoteAudioStats& stats) override;
#pragma endregion

    private:
        // Called when a method is called on this plugin's channel from Dart.
        void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue>& method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

        IRtcEngine* agoraRtcEngine;

        std::unique_ptr<flutter::BasicMessageChannel<EncodableValue>> messageChannel;

        void SendEvent(std::string name, EncodableMap params)
        {
            params[EncodableValue("event")] = name;
            messageChannel->Send(EncodableValue(params));
        }
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

        plugin->messageChannel = std::make_unique<flutter::BasicMessageChannel<EncodableValue>>(
            registrar->messenger(),
            "agora_rtc_engine_message_channel",
            &flutter::StandardMessageCodec::GetInstance());

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
        auto params = method_call.arguments() != nullptr ? method_call.arguments()->MapValue() : EncodableMap();
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
        else if ("destroy" == methodName)
        {
            agoraRtcEngine->release();
            agoraRtcEngine = nullptr;
            result->Success(nullptr);
        }
        else if ("setChannelProfile" == methodName)
        {
            auto profile = params[EncodableValue("profile")].IntValue();
            agoraRtcEngine->setChannelProfile(static_cast<CHANNEL_PROFILE_TYPE>(profile));
            result->Success(nullptr);
        }
        else if ("joinChannel" == methodName)
        {
            auto token = params.count(EncodableValue("token")) > 0 ? params[EncodableValue("token")].StringValue() : "";
            auto channelId = params[EncodableValue("channelId")].StringValue();
            auto info = params.count(EncodableValue("info")) > 0 ? params[EncodableValue("info")].StringValue() : "";
            auto uid = params[EncodableValue("uid")].IntValue();
            agoraRtcEngine->joinChannel(token.c_str(), channelId.c_str(), info.c_str(), uid);
            auto ret = EncodableValue(true);
            result->Success(&ret);
        }
        else if ("leaveChannel" == methodName)
        {
            auto success = agoraRtcEngine->leaveChannel() == 0;
            auto ret = EncodableValue(success);
            result->Success(&ret);
        }
        else if ("muteLocalAudioStream" == methodName)
        {
            auto muted = params[EncodableValue("muted")].BoolValue();
            agoraRtcEngine->muteLocalAudioStream(muted);
            result->Success(nullptr);
        }
        else if ("muteAllRemoteAudioStreams" == methodName)
        {
            auto muted = params[EncodableValue("muted")].BoolValue();
            agoraRtcEngine->muteAllRemoteAudioStreams(muted);
            result->Success(nullptr);
        }
        else
            result->NotImplemented();
    }

#pragma region IRtcEngineEventHandler
    void AgoraRtcEnginePlugin::onUserJoined(uid_t uid, int elapsed)
    {
        SendEvent("onUserJoined", EncodableMap{
            {EncodableValue("uid"), EncodableValue((int)uid)},
            {EncodableValue("elapsed"), EncodableValue(elapsed)},
        });
    }

    void AgoraRtcEnginePlugin::onUserOffline(uid_t uid, USER_OFFLINE_REASON_TYPE reason)
    {
        SendEvent("onUserOffline", EncodableMap{
            {EncodableValue("uid"), EncodableValue((int)uid)},
            {EncodableValue("reason"), EncodableValue((int)reason)},
        });
    }

    void AgoraRtcEnginePlugin::onRtcStats(const RtcStats& stats)
    {
        SendEvent("onRtcStats", EncodableMap{
            {EncodableValue("stats"), EncodableValue(EncodableMap{
                {EncodableValue("totalDuration"), EncodableValue((int)stats.duration)},
                {EncodableValue("txBytes"), EncodableValue((int)stats.txBytes)},
                {EncodableValue("rxBytes"), EncodableValue((int)stats.rxBytes)},
                {EncodableValue("txAudioBytes"), EncodableValue((int)stats.txAudioBytes)},
                {EncodableValue("txVideoBytes"), EncodableValue((int)stats.txVideoBytes)},
                {EncodableValue("rxAudioBytes"), EncodableValue((int)stats.rxAudioBytes)},
                {EncodableValue("rxVideoBytes"), EncodableValue((int)stats.rxVideoBytes)},
                {EncodableValue("txKBitrate"), EncodableValue((int)stats.txKBitRate)},
                {EncodableValue("rxKBitrate"), EncodableValue((int)stats.rxKBitRate)},
                {EncodableValue("txAudioKBitrate"), EncodableValue((int)stats.txAudioKBitRate)},
                {EncodableValue("rxAudioKBitrate"), EncodableValue((int)stats.rxAudioKBitRate)},
                {EncodableValue("txVideoKBitrate"), EncodableValue((int)stats.txVideoKBitRate)},
                {EncodableValue("rxVideoKBitrate"), EncodableValue((int)stats.rxVideoKBitRate)},
                {EncodableValue("lastmileDelay"), EncodableValue((int)stats.lastmileDelay)},
                {EncodableValue("txPacketLossRate"), EncodableValue((int)stats.txPacketLossRate)},
                {EncodableValue("rxPacketLossRate"), EncodableValue((int)stats.rxPacketLossRate)},
                {EncodableValue("users"), EncodableValue((int)stats.userCount)},
                {EncodableValue("cpuAppUsage"), EncodableValue((int)stats.cpuAppUsage)},
                {EncodableValue("cpuTotalUsage"), EncodableValue((int)stats.cpuTotalUsage)},
            })},
            });
    }

    void AgoraRtcEnginePlugin::onRemoteAudioStats(const RemoteAudioStats& stats)
    {
        SendEvent("onRemoteAudioStats", EncodableMap{
            {EncodableValue("stats"), EncodableValue(EncodableMap{
                {EncodableValue("uid"), EncodableValue((int)stats.uid)},
                {EncodableValue("quality"), EncodableValue(stats.quality)},
                {EncodableValue("networkTransportDelay"), EncodableValue(stats.networkTransportDelay)},
                {EncodableValue("jitterBufferDelay"), EncodableValue(stats.jitterBufferDelay)},
                {EncodableValue("audioLossRate"), EncodableValue(stats.audioLossRate)},
                {EncodableValue("numChannels"), EncodableValue(stats.numChannels)},
                {EncodableValue("receivedSampleRate"), EncodableValue(stats.receivedSampleRate)},
                {EncodableValue("receivedBitrate"), EncodableValue(stats.receivedBitrate)},
                {EncodableValue("totalFrozenTime"), EncodableValue(stats.totalFrozenTime)},
                {EncodableValue("frozenRate"), EncodableValue(stats.frozenRate)},
            })},
            });
    }
#pragma endregion
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
