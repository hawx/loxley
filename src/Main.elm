module Main exposing (main)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Navigation
import RemoteData exposing (WebData)


main =
    Navigation.program UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Stream =
    { context : String
    , summary : String
    , type_ : String
    , orderedItems : List Activity
    }


decodeStream : Decode.Decoder Stream
decodeStream =
    Pipeline.decode Stream
        |> Pipeline.required "@context" Decode.string
        |> Pipeline.required "summary" Decode.string
        |> Pipeline.required "type" Decode.string
        |> Pipeline.required "orderedItems" (Decode.list decodeActivity)


type alias Activity =
    { id : String
    , type_ : String
    , published : String
    , actor : Actor
    , summary : String
    , object : Object
    , target : Target
    }


decodeActivity : Decode.Decoder Activity
decodeActivity =
    Pipeline.decode Activity
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "type" Decode.string
        |> Pipeline.required "published" Decode.string
        |> Pipeline.required "actor" decodeActor
        |> Pipeline.required "summary" Decode.string
        |> Pipeline.required "object" decodeObject
        |> Pipeline.required "target" decodeTarget


type alias Actor =
    { id : String
    , name : String
    }


decodeActor : Decode.Decoder Actor
decodeActor =
    Pipeline.decode Actor
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string


type alias Object =
    { id : String
    , content : String
    }


decodeObject : Decode.Decoder Object
decodeObject =
    Pipeline.decode Object
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "content" Decode.string


type alias Target =
    { type_ : String
    , name : String
    }


decodeTarget : Decode.Decoder Target
decodeTarget =
    Pipeline.decode Target
        |> Pipeline.required "type" Decode.string
        |> Pipeline.required "name" Decode.string


type alias Model =
    { streamInput : String
    , streamContent : WebData Stream
    }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    case parseRoute location of
        Just stream ->
            { streamInput = stream
            , streamContent = RemoteData.Loading
            }
                ! [ RemoteData.sendRequest (requestStream stream) |> Cmd.map StreamResponse
                  ]

        Nothing ->
            { streamInput = ""
            , streamContent = RemoteData.NotAsked
            }
                ! []


type Msg
    = UrlChange Navigation.Location
    | StreamInput String
    | LoadStream
    | StreamResponse (WebData Stream)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            model ! []

        StreamInput text ->
            { model | streamInput = text } ! []

        LoadStream ->
            { model | streamContent = RemoteData.Loading }
                ! [ navigate (Just model.streamInput)
                  , RemoteData.sendRequest (requestStream model.streamInput) |> Cmd.map StreamResponse
                  ]

        StreamResponse webData ->
            { model | streamContent = Debug.log "response" webData } ! []


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.div [ Attr.class "section" ]
            [ Html.div [ Attr.class "container" ]
                [ Html.div [ Attr.class "field has-addons has-addons-centered" ]
                    [ Html.p [ Attr.class "control" ]
                        [ Html.input
                            [ Attr.class "input"
                            , Attr.placeholder "Activity Stream URL"
                            , Attr.defaultValue model.streamInput
                            , Event.onInput StreamInput
                            ]
                            []
                        ]
                    , Html.p [ Attr.class "control" ]
                        [ Html.button
                            [ Attr.class "button is-info"
                            , Attr.classList [ ( "is-loading", RemoteData.isLoading model.streamContent ) ]
                            , Event.onClick LoadStream
                            ]
                            [ Html.text "Load" ]
                        ]
                    ]
                ]
            ]
        , case model.streamContent of
            RemoteData.Success stream ->
                streamView stream

            _ ->
                Html.text ""
        ]


streamView : Stream -> Html msg
streamView stream =
    Html.div [ Attr.class "section" ]
        [ Html.div [ Attr.class "container" ]
            [ Html.h2 [ Attr.class "title is-4" ] [ Html.text stream.summary ]
            , Html.div [] (List.map activityView stream.orderedItems)
            ]
        ]


activityView : Activity -> Html msg
activityView activity =
    Html.article [ Attr.class "media" ]
        [ Html.div [ Attr.class "media-content" ]
            [ Html.div [ Attr.class "content" ]
                [ Html.text activity.summary
                , Html.br [] []
                , Html.small [] [ Html.text activity.published ]
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


requestStream : String -> Http.Request Stream
requestStream stream =
    Http.get stream decodeStream


parseRoute : Navigation.Location -> Maybe String
parseRoute location =
    if String.startsWith "?stream=" location.search then
        Http.decodeUri (String.dropLeft 8 location.search)
    else
        Nothing


toUrl : Maybe String -> String
toUrl stream =
    case stream of
        Just url ->
            "/?stream=" ++ Http.encodeUri url

        Nothing ->
            "/"


navigate : Maybe String -> Cmd msg
navigate stream =
    Navigation.newUrl (toUrl stream)
