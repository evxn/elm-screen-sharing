port module Main exposing (..)

import Browser
import Debug exposing (toString)
import Enforce exposing (WebRTC)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (Value)
import Json.Encode exposing (Value)
import List.NonEmpty.Zipper as Zipper exposing (Zipper)


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


type Msg
    = GotMessage Value
      -- | GotFrame Frame
      -- | GotRoleBit Role
      -- | GotSupportedTechs SupportedTechs
      -- | Failed Tech String
      -- | AcknowledgedWebRTC Enforce.WebRTC
      -- | AcknowledgedVNC Enforce.VNC
      -- | GotSources (Zipper Source)
      -- | GotMobile Enforce.Mobile
      -- | GotDesktop Enforce.Desktop
    | StartClicked (Zipper Tech)
    | SelectScreenClicked (Zipper Source)
    | SelectWindowClicked (Zipper Source)
    | SelectedSource (Zipper Source)
    | PopupDissmisClicked
    | PopupSaveClicked (Zipper Source)
    | PopupTabClicked PopupTab
    | PauseClicked
    | ResumeClicked
    | StopClicked


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
    = ScreensTab
    | WindowsTab


type Popup extraInfo
    = Open extraInfo
    | Closed


init : () -> ( Model, Cmd Msg )
init _ =
    ( WaitingForRole
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        screen =
            Zipper.singleton (Screen { title = "Tets", id = 0 })

        window =
            Zipper.singleton (Window { title = "Tets", id = 0 })
    in
    wrapper "page"
        (case model of
            WaitingForRole ->
                [ loader ]

            ParticipantReady Nothing ->
                [ text "Waiting for presentation to start" ]

            ParticipantReady (Just frame) ->
                [ preview frame ]

            WaitingForSupportedTechs ->
                [ loader ]

            NotInitiatedAck supportedTechs ->
                -- bottom class has absolute positioning, floating over the screen like buttons in Skype
                [ wrapper "bottom"
                    [ button [ onClick (StartClicked supportedTechs) ] [ text "Start" ] ]
                ]

            WaitingForAck _ ->
                [ loader, wrapper "bottom" [ disabledButton "Start" ] ]

            FailedAck supportedTechs error ->
                if Zipper.hasNext supportedTechs then
                    [ loader, wrapper "bottom" [ disabledButton "Start" ] ]

                else
                    [ text error ]

            VNCWaitingForMobileFlag _ _ ->
                [ loader, wrapper "bottom" [ disabledButton "Start" ] ]

            VNCMobileReady _ transmissionStatus _ _ ->
                case transmissionStatus of
                    WaitingForSources _ ->
                        [ text "This branch never gets executed" ]

                    Ready _ _ ->
                        [ text "This branch never gets executed" ]

                    Active _ frame ->
                        [ h1 [] [ text "Mobile Display" ]
                        , preview frame
                        , wrapper "bottom"
                            [ button [ onClick StopClicked ] [ text "Stop" ]
                            , button [ onClick PauseClicked ] [ text "Pause" ]
                            ]
                        ]

                    Paused _ ->
                        [ h1 [] [ text "Mobile Display" ]
                        , wrapper "bottom"
                            [ button [ onClick StopClicked ] [ text "Stop" ]
                            , button [ onClick ResumeClicked ] [ text "Resume" ]
                            ]
                        ]

            VNCDesktopReady _ data _ _ ->
                []

            WebRTCReady _ data _ ->
                []
        )



-- h1 [] [ text "Mobile Display" ]
--         , preview frame
--         , div []
--             [ button [ onClick (StartClicked tech) ] [ text "Start" ]
--             , button [ onClick StopClicked ] [ text "Stop" ]
--             , button [ onClick PauseClicked ] [ text "Pause" ]
--             , button [ onClick ResumeClicked ] [ text "Resume" ]
--             , button [ onClick (SelectScreenClicked screen) ] [ text "Select Screen" ]
--             , button [ onClick (SelectWindowClicked window) ] [ text "Select Window" ]
--             ]


loader : Html msg
loader =
    div [] [ text "Loading" ]


wrapper : String -> List (Html msg) -> Html msg
wrapper className content =
    div
        [ class className ]
        content


disabledButton : String -> Html Msg
disabledButton name =
    button
        [ disabled True ]
        [ text name ]


popup : Zipper Source -> PopupTab -> Html Msg
popup source activeTab =
    div [ class "popup" ]
        [ div []
            [ nav []
                [ ul []
                    [ li
                        [ classList [ ( "active", activeTab == ScreensTab ) ]
                        , onClick (PopupTabClicked ScreensTab)
                        ]
                        [ text "Screens" ]
                    , li
                        [ classList [ ( "active", activeTab == WindowsTab ) ]
                        , onClick (PopupTabClicked WindowsTab)
                        ]
                        [ text "Windows" ]
                    ]
                ]
            , div [ class "popup-body" ]
                [ ul []
                    [ li
                        [ onClick (SelectedSource source) ]
                        [ text "Screen 1" ]
                    ]
                ]
            ]
        , div []
            [ button [ class "btn-primary", onClick (PopupSaveClicked source) ] [ text "Save" ]
            , button [ onClick PopupDissmisClicked ] [ text "Close" ]
            ]
        ]


previewCanvas : List (Attribute msg) -> List (Html msg) -> Html msg
previewCanvas attributes children =
    -- assume there is a custom element
    node "preview-canvas" attributes children


preview : Frame -> Html msg
preview (Frame frame) =
    previewCanvas
        [ property "frame" (Json.Encode.string frame) ]
        []


transmissionLabel : SourceData -> String
transmissionLabel { title, id } =
    title ++ " - " ++ toString id


showPause : TransmissionStatus a b -> Bool
showPause status =
    case status of
        WaitingForSources _ ->
            False

        Ready _ _ ->
            False

        Active _ _ ->
            True

        Paused _ ->
            False
