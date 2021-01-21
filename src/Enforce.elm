module Enforce exposing
    ( Desktop
    , Mobile
    , VNC
    , WebRTC
    , decoderDesktop
    , decoderMobile
    , decoderVNC
    , decoderWebRTC
    )

import Json.Decode exposing (Decoder, succeed)


type WebRTC
    = WebRTC


type VNC
    = VNC


type Mobile
    = Mobile


type Desktop
    = Desktop


decoderWebRTC : Decoder WebRTC
decoderWebRTC =
    succeed WebRTC


decoderVNC : Decoder VNC
decoderVNC =
    succeed VNC


decoderMobile : Decoder Mobile
decoderMobile =
    succeed Mobile


decoderDesktop : Decoder Desktop
decoderDesktop =
    succeed Desktop
