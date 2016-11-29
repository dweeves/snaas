module Console exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, href, placeholder, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Navigation
import UrlParser as Url exposing ((</>), (<?>), s, int, stringParam, top)

import App

main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


-- MODEL

type alias Flags =
    { zone : String
    }

type alias Model =
    { appModel : App.Model
    , debug : Bool
    , route : (Maybe Route)
    , zone : String
    }

type alias Tag = List (Html Msg) -> Html Msg

type Route
    = Apps
    | Home

init : Flags -> Navigation.Location -> (Model, Cmd Msg)
init {zone} location =
    case (Url.parsePath route location) of
        Nothing ->
            (Model App.initModel (isDebug location) (Url.parsePath route location) zone, Cmd.none)
        Just Apps ->
            let
                (appModel, appCmd) = App.init
            in
                (Model appModel (isDebug location) (Url.parsePath route location) zone, Cmd.map AppMsg appCmd)
        Just Home ->
            (Model App.initModel (isDebug location) (Url.parsePath route location) zone, Cmd.none)

-- UPDATE

type Msg
    = AppMsg App.Msg
    | Navigate String
    | UrlChange Navigation.Location

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        AppMsg appMsg ->
            let
                (appModel, appCmd) = App.update appMsg model.appModel
            in
                ({ model | appModel = appModel }, Cmd.map AppMsg appCmd)
        Navigate path ->
            (model, Navigation.newUrl path)
        UrlChange location ->
            let
                newRoute = Url.parsePath route location
            in
                if newRoute == Just Apps then
                    let
                        (appModel, appCmd) = App.init
                    in
                        ({ model | appModel = appModel, route = newRoute }, Cmd.map AppMsg appCmd)
                else
                    ({ model | route = newRoute }, Cmd.none)

-- SUBSCRIPTION

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- VIEW

view : Model -> Html Msg
view model =
    let
        content = case model.route of
            Nothing ->
                h3 [] [ text "Looks like we couldn't find the page you were looking for." ]
            Just Apps ->
                Html.map AppMsg (App.view model.appModel)
            Just Home ->
                h3 [] [ text "You are home now." ]
    in
        div [ class "content" ]
            [ viewContainer (header [])
                [ viewHeader
                , nav [] [ span [] [ text model.zone ] ]
                ]
            , viewContainer (section [])
                [ h2 []
                    [ a [ onClick (Navigate "/apps"), title "Apps" ]
                        [ span [ class "icon nc-icon-glyph ui-2_layers" ] []
                        , span [] [ text "Apps" ]
                        ]
                    ]
                ]
            , viewContainer (section [ class "highlight" ]) [ content ]
            , viewContainer (footer []) [ viewDebug model ]
            ]

viewContainer : Tag -> List (Html Msg) -> Html Msg
viewContainer elem content =
    elem
        [ div [ class "container" ]
            content
        ]

viewDebug : Model -> Html Msg
viewDebug model =
    if model.debug then
        div [ class "debug" ]
          [ text (toString model)
          ]
    else
        div [] []

viewHeader : Html Msg
viewHeader =
    h1 []
        [ a [ onClick (Navigate "/"), title "Home" ]
            [ strong [] [ text "SocialPath" ]
            , span [] [ text "Console" ]
            ]
        ]

-- ROUTING

route : Url.Parser (Route -> a) a
route =
    Url.oneOf
        [ Url.map Apps (Url.s "apps")
        , Url.map Home (Url.s "")
        ]

isDebug : Navigation.Location -> Bool
isDebug location =
    let
        debug = Url.parsePath (Url.s "" <?> stringParam "debug") location
    in
        case debug of
            Nothing ->
                False
            Just debug ->
                Maybe.withDefault "false" debug == "true"
