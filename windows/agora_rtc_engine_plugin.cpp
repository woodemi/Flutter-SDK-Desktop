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
#include "include/agora_rtc_engine/agora_rtc_engine_plugin.h"

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

    EncodableMap toMap(const RtcStats& stats)
    {
        return EncodableMap{
            {"totalDuration", (int)stats.duration},
            {"txBytes", (int)stats.txBytes},
            {"rxBytes", (int)stats.rxBytes},
            {"txAudioBytes", (int)stats.txAudioBytes},
            {"txVideoBytes", (int)stats.txVideoBytes},
            {"rxAudioBytes", (int)stats.rxAudioBytes},
            {"rxVideoBytes", (int)stats.rxVideoBytes},
            {"txKBitrate", (int)stats.txKBitRate},
            {"rxKBitrate", (int)stats.rxKBitRate},
            {"txAudioKBitrate", (int)stats.txAudioKBitRate},
            {"rxAudioKBitrate", (int)stats.rxAudioKBitRate},
            {"txVideoKBitrate", (int)stats.txVideoKBitRate},
            {"rxVideoKBitrate", (int)stats.rxVideoKBitRate},
            {"lastmileDelay", (int)stats.lastmileDelay},
            {"txPacketLossRate", (int)stats.txPacketLossRate},
            {"rxPacketLossRate", (int)stats.rxPacketLossRate},
            {"users", (int)stats.userCount},
            {"cpuAppUsage", stats.cpuAppUsage},
            {"cpuTotalUsage", stats.cpuTotalUsage},
        };
    }

    class AgoraRtcEnginePlugin : public flutter::Plugin, IRtcEngineEventHandler
    {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

        AgoraRtcEnginePlugin();

        virtual ~AgoraRtcEnginePlugin();

#pragma region IRtcEngineEventHandler
    	void onJoinChannelSuccess(const char* channel, uid_t uid, int elapsed) override;
    	void onLeaveChannel(const RtcStats& stats) override;
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
            messageChannel->Send(params);
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
        auto params = method_call.arguments()->IsNull() ? EncodableMap() : std::get<EncodableMap>(*method_call.arguments());
        DebugPrintLine("plugin HandleMethodCall " + methodName + ", args: " + std::to_string(params.size()));

        if ("requestAVPermissions" == methodName)
        {
	        // ignore macOS method
            result->Success(EncodableValue(true));
        }
        else if ("create" == methodName)
        {
            auto appId = std::get<std::string>(params[EncodableValue("appId")]);
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
            auto profile = std::get<int>(params[EncodableValue("profile")]);
            agoraRtcEngine->setChannelProfile(static_cast<CHANNEL_PROFILE_TYPE>(profile));
            result->Success(nullptr);
        }
        else if ("joinChannel" == methodName)
        {
            auto token = params[EncodableValue("token")].IsNull() ? "" : std::get<std::string>(params[EncodableValue("token")]);
            auto channelId = std::get<std::string>(params[EncodableValue("channelId")]);
            auto info = params[EncodableValue("info")].IsNull() ? "" : std::get<std::string>(params[EncodableValue("info")]);
            auto uid = std::get<int>(params[EncodableValue("uid")]);
            agoraRtcEngine->joinChannel(token.c_str(), channelId.c_str(), info.c_str(), uid);
            result->Success(EncodableValue(true));
        }
        else if ("leaveChannel" == methodName)
        {
            auto success = agoraRtcEngine->leaveChannel() == 0;
            result->Success(EncodableValue(success));
        }
        else if ("muteLocalAudioStream" == methodName)
        {
            auto muted = std::get<bool>(params[EncodableValue("muted")]);
            agoraRtcEngine->muteLocalAudioStream(muted);
            result->Success(nullptr);
        }
        else if ("muteAllRemoteAudioStreams" == methodName)
        {
            auto muted = std::get<bool>(params[EncodableValue("muted")]);
            agoraRtcEngine->muteAllRemoteAudioStreams(muted);
            result->Success(nullptr);
        }
        else
            result->NotImplemented();
    }

#pragma region IRtcEngineEventHandler
    void AgoraRtcEnginePlugin::onJoinChannelSuccess(const char* channel, uid_t uid, int elapsed)
    {
        SendEvent("onJoinChannelSuccess", EncodableMap{
            {"channel", channel},
            {"uid", (int)uid},
            {"elapsed", elapsed},
        });
    }

    void AgoraRtcEnginePlugin::onLeaveChannel(const RtcStats& stats)
    {
        SendEvent("onLeaveChannel", EncodableMap{
            {"stats", toMap(stats)},
        });
    }

    void AgoraRtcEnginePlugin::onUserJoined(uid_t uid, int elapsed)
    {
        SendEvent("onUserJoined", EncodableMap{
            {"uid", (int)uid},
            {"elapsed", elapsed},
        });
    }

    void AgoraRtcEnginePlugin::onUserOffline(uid_t uid, USER_OFFLINE_REASON_TYPE reason)
    {
        SendEvent("onUserOffline", EncodableMap{
            {"uid", (int)uid},
            {"reason", (int)reason},
        });
    }

    void AgoraRtcEnginePlugin::onRtcStats(const RtcStats& stats)
    {
        SendEvent("onRtcStats", EncodableMap{
            {"stats", toMap(stats)},
        });
    }

    void AgoraRtcEnginePlugin::onRemoteAudioStats(const RemoteAudioStats& stats)
    {
        SendEvent("onRemoteAudioStats", EncodableMap{
            {"stats", EncodableMap{
                {"uid", (int)stats.uid},
                {"quality", stats.quality},
                {"networkTransportDelay", stats.networkTransportDelay},
                {"jitterBufferDelay", stats.jitterBufferDelay},
                {"audioLossRate", stats.audioLossRate},
                {"numChannels", stats.numChannels},
                {"receivedSampleRate", stats.receivedSampleRate},
                {"receivedBitrate", stats.receivedBitrate},
                {"totalFrozenTime", stats.totalFrozenTime},
                {"frozenRate", stats.frozenRate},
            }},
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
