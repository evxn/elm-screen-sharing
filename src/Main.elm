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
    | GotFrame Frame
    | GotRoleBit Role
    | GotSupportedTechs SupportedTechs
    | Failed Tech String
    | AcknowledgedWebRTC Enforce.WebRTC
    | AcknowledgedVNC Enforce.VNC
    | GotSources (Zipper Source)
    | GotMobile Enforce.Mobile
    | GotDesktop Enforce.Desktop
    | StartClicked (Zipper Tech)
    | SelectScreenClicked (Zipper Source)
    | SelectWindowClicked (Zipper Source)
    | SelectedSource Source
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
      -- enforcement arguments cannot be created directly. you can only get one from a specific message
    | VNCWaitingForMobileFlag SupportedTechs Enforce.VNC
    | VNCMobileReady SupportedTechs SingleSource Enforce.VNC Enforce.Mobile
    | VNCDesktopReady SupportedTechs MultipleSources Enforce.VNC Enforce.Desktop
    | WebRTCReady SupportedTechs MultipleSources Enforce.WebRTC


type alias SupportedTechs =
    Zipper Tech


type alias SingleSource =
    TransmissionStatus () Never


type alias MultipleSources =
    { transmission : TransmissionStatus (Zipper Source) ()
    , popup : Popup
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


type Popup
    = Open (Zipper PopupTab)
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

            VNCMobileReady _ transmission _ _ ->
                case transmission of
                    WaitingForSources _ ->
                        [ text "This branch Never gets executed" ]

                    Ready _ _ ->
                        [ text "This branch Never gets executed" ]

                    Active _ frame ->
                        [ h1 [] [ text "Mobile Display" ]
                        , preview frame
                        , wrapper "bottom"
                            [ stopButton
                            , pauseButton
                            ]
                        ]

                    Paused _ ->
                        [ h1 [] [ text "Mobile Display" ]
                        , wrapper "bottom"
                            [ stopButton
                            , resumeButton
                            ]
                        ]

            VNCDesktopReady _ { transmission, popup } _ _ ->
                case transmission of
                    WaitingForSources _ ->
                        [ wrapper "bottom"
                            [ stopButton ]
                        ]

                    Ready sources _ ->
                        [ wrapper "bottom"
                            [ stopButton
                            , selectScreenButton sources
                            , selectWindowButton sources
                            ]
                        , popupView transmission sources popup
                        ]

                    Active sources frame ->
                        [ h1 []
                            [ Zipper.current sources
                                |> transmissionSourceLabel
                                |> text
                            ]
                        , preview frame
                        , wrapper "bottom"
                            [ stopButton
                            , selectScreenButton sources
                            , selectWindowButton sources
                            , pauseButton
                            ]
                        , popupView transmission sources popup
                        ]

                    Paused sources ->
                        [ h1 []
                            [ Zipper.current sources
                                |> transmissionSourceLabel
                                |> text
                            ]
                        , wrapper "bottom"
                            [ stopButton
                            , selectScreenButton sources
                            , selectWindowButton sources
                            , resumeButton
                            ]
                        , popupView transmission sources popup
                        ]

            WebRTCReady _ { transmission, popup } _ ->
                case transmission of
                    WaitingForSources _ ->
                        [ wrapper "bottom"
                            [ stopButton ]
                        ]

                    Ready sources _ ->
                        [ wrapper "bottom"
                            [ stopButton
                            , selectScreenButton sources
                            ]
                        , popupView transmission sources popup
                        ]

                    Active sources frame ->
                        [ h1 []
                            [ Zipper.current sources
                                |> transmissionSourceLabel
                                |> text
                            ]
                        , preview frame
                        , wrapper "bottom"
                            [ stopButton
                            , selectScreenButton sources
                            , pauseButton
                            ]
                        , popupView transmission sources popup
                        ]

                    Paused sources ->
                        [ h1 []
                            [ Zipper.current sources
                                |> transmissionSourceLabel
                                |> text
                            ]
                        , wrapper "bottom"
                            [ stopButton
                            , selectScreenButton sources
                            , resumeButton
                            ]
                        , popupView transmission sources popup
                        ]
        )


wrapper : String -> List (Html msg) -> Html msg
wrapper className content =
    div
        [ class className ]
        content


loader : Html msg
loader =
    div [] [ text "Loading" ]


disabledButton : String -> Html Msg
disabledButton name =
    button
        [ disabled True ]
        [ text name ]


previewCanvas : List (Attribute msg) -> List (Html msg) -> Html msg
previewCanvas attributes children =
    -- assume there is a custom element
    node "preview-canvas" attributes children


preview : Frame -> Html msg
preview (Frame frame) =
    previewCanvas
        [ property "frame" (Json.Encode.string frame) ]
        []


transmissionSourceLabel : Source -> String
transmissionSourceLabel source =
    case source of
        Screen data ->
            transmissionLabelHelper data

        Window data ->
            transmissionLabelHelper data


transmissionLabelHelper : SourceData -> String
transmissionLabelHelper { title, id } =
    title ++ " - " ++ toString id


stopButton : Html Msg
stopButton =
    button [ onClick StopClicked ] [ text "Stop" ]


resumeButton : Html Msg
resumeButton =
    button [ onClick ResumeClicked ] [ text "Resume" ]


pauseButton : Html Msg
pauseButton =
    button [ onClick PauseClicked ] [ text "Pause" ]


selectScreenButton : Zipper Source -> Html Msg
selectScreenButton sources =
    button [ onClick (SelectScreenClicked sources) ] [ text "Select Screen" ]


selectWindowButton : Zipper Source -> Html Msg
selectWindowButton sources =
    button [ onClick (SelectWindowClicked sources) ] [ text "Select Window" ]


popupView : TransmissionStatus (Zipper Source) pending -> Zipper Source -> Popup -> Html Msg
popupView transmission sources popup =
    case popup of
        Closed ->
            emptyNode

        Open tabs ->
            let
                selectedSource =
                    case transmission of
                        WaitingForSources _ ->
                            Nothing

                        Ready _ _ ->
                            Nothing

                        Active _ _ ->
                            Just (Zipper.current sources)

                        Paused _ ->
                            Just (Zipper.current sources)
            in
            wrapper "popup"
                [ popupNavView tabs
                , wrapper "popup-body" (popupBody selectedSource sources tabs)
                , wrapper "popup-footer"
                    [ button [ onClick PopupDissmisClicked ] [ text "Close" ]
                    , button [ class "btn-primary", onClick (PopupSaveClicked sources) ] [ text "Save" ]
                    ]
                ]


popupNavView : Zipper PopupTab -> Html Msg
popupNavView tabs =
    let
        currentTab =
            Zipper.current tabs
    in
    if Zipper.length tabs > 1 then
        wrapper "popup-nav"
            [ nav []
                [ ul []
                    (Zipper.toList
                        tabs
                        |> List.map (\tab -> popupTabView (currentTab == tab) tab)
                    )
                ]
            ]

    else
        emptyNode


popupTabView : Bool -> PopupTab -> Html Msg
popupTabView isActive tab =
    li
        [ classList [ ( "active", isActive ) ]
        , onClick (PopupTabClicked tab)
        ]
        [ popupTabLabel tab |> text ]


popupTabLabel : PopupTab -> String
popupTabLabel tab =
    case tab of
        ScreensTab ->
            "Screens"

        WindowsTab ->
            "Windows"


popupBody : Maybe Source -> Zipper Source -> Zipper PopupTab -> List (Html Msg)
popupBody selectedSource sources tabs =
    Zipper.toList sources
        |> filterSourcesForTab (Zipper.current tabs)
        |> List.map
            (\source ->
                let
                    isActive =
                        sourceIsActive selectedSource sources
                in
                selectableItemView isActive source
            )


selectableItemView : Bool -> Source -> Html Msg
selectableItemView isActive source =
    li
        [ classList [ ( "active", isActive ) ], onClick (SelectedSource source) ]
        [ source |> transmissionSourceLabel |> text ]


sourceIsActive : Maybe Source -> Zipper Source -> Bool
sourceIsActive maybeSource sources =
    case maybeSource of
        Just source ->
            Zipper.current sources == source

        Nothing ->
            False


isScreenSource : Source -> Bool
isScreenSource source =
    case source of
        Screen _ ->
            True

        Window _ ->
            False


isWindowSource : Source -> Bool
isWindowSource source =
    case source of
        Screen _ ->
            False

        Window _ ->
            True


filterSourcesForTab : PopupTab -> List Source -> List Source
filterSourcesForTab tab sources =
    List.filter
        (case tab of
            ScreensTab ->
                isScreenSource

            WindowsTab ->
                isWindowSource
        )
        sources


emptyNode : Html msg
emptyNode =
    text ""
