port module Main exposing (..)

import Browser
import Enforce
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (Value)
import List.NonEmpty.Zipper exposing (Zipper)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


port sendMessage : Value -> Cmd msg


port onMessage : (Value -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    onMessage GotMessage


type Role
    = Participant
    | Presenter


type Frame
    = Frame String


type Tech
    = WebRTC
    | VNC


type alias SourceData =
    { title : String
    , id : Int
    }


type Source
    = Screen SourceData
    | Window SourceData


type PopupTab
    = Screens
    | Windows


type Popup extraInfo
    = Open extraInfo
    | Closed


type alias SupportedTechs =
    Zipper Tech


type alias SingleSource =
    TransmissionStatus () Never


type alias MultipleSources popupExtraInfo =
    { transmission : TransmissionStatus (Zipper Source) ()
    , popup : Popup popupExtraInfo
    }


type TransmissionStatus source pending
    = WaitingForSources pending
    | Ready source pending
    | Active source Frame
    | Paused source


type Model
    = WaitingForRole
    | ParticipantReady (Maybe Frame)
    | WaitingForSupportedTechs
    | NotInitiatedAck SupportedTechs
    | WaitingForAck SupportedTechs
    | FailedAck SupportedTechs String
    | VNCWaitingForMobileFlag SupportedTechs Enforce.VNC
    | VNCMobileReady SupportedTechs SingleSource Enforce.VNC Enforce.Mobile
    | VNCDesktopReady SupportedTechs (MultipleSources PopupTab) Enforce.VNC Enforce.Desktop
    | WebRTCReady SupportedTechs (MultipleSources ()) Enforce.WebRTC


type Msg
    = GotMessage Value
    | GotFrame Frame
    | GotRoleBit Role
    | GotSupportedTechs SupportedTechs
    | Failed Tech String
    | AcknowledgedWebRTC Enforce.WebRTC
    | AcknowledgedVNC Enforce.VNC
    | GotSources (Zipper Source)
    | GotMobile Enforce.Mobile
    | GotDesktop Enforce.Desktop
    | StartClicked Tech
    | SelectScreenClicked (Zipper Source)
    | SelectWindowClicked (Zipper Source)
    | SelectedSource (Zipper Source)
    | PopupDissmisClicked
    | PopupSaveClicked (Zipper Source)
    | PauseClicked
    | ResumeClicked
    | StopClicked


init : () -> ( Model, Cmd Msg )
init _ =
    ( WaitingForRole
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [] []
