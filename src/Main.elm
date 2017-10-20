module Main exposing (main)

import Html exposing (Html)
import Navigation


main =
    Navigation.program UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    {}


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    {} ! []


type Msg
    = UrlChange Navigation.Location


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            model ! []


view : Model -> Html Msg
view model =
    Html.div [] []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
