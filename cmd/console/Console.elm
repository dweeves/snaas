module Console exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, href, id, placeholder, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Navigation
import UrlParser as Url exposing ((</>), (<?>), s, int, stringParam, top)

import App
import Route

main : Program Flags Model Msg
main =
    Navigation.programWithFlags LocationChange
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
    , route : (Maybe Route.Route)
    , zone : String
    }

type alias Tag = List (Html Msg) -> Html Msg

init : Flags -> Navigation.Location -> (Model, Cmd Msg)
init {zone} location =
    let
        route = Route.parse location
    in
        case route of
            Nothing ->
                (Model App.initModel (isDebug location) route zone, Cmd.none)
            Just (Route.App id) ->
                (Model App.initModel (isDebug location) route zone, Cmd.none)
            Just Route.Apps ->
                let
                    (appModel, appCmd) = App.init
                in
                    (Model appModel (isDebug location) route zone, Cmd.map AppMsg appCmd)
            Just Route.Home ->
                (Model App.initModel (isDebug location) route zone, Cmd.none)

-- UPDATE

type Msg
    = AppMsg App.Msg
    | LocationChange Navigation.Location
    | NavigateApp String
    | NavigateApps
    | NavigateHome

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        AppMsg appMsg ->
            let
                (appModel, appCmd) = App.update appMsg model.appModel
            in
                ({ model | appModel = appModel }, Cmd.map AppMsg appCmd)
        LocationChange location ->
            let
                newRoute = Route.parse location
            in
                if newRoute == Just Route.Apps then
                    let
                        (appModel, appCmd) = App.init
                    in
                        ({ model | appModel = appModel, route = newRoute }, Cmd.map AppMsg appCmd)
                else
                    ({ model | route = newRoute }, Cmd.none)
        NavigateApp id ->
            (model, Navigation.newUrl (Route.construct (Route.App id)))
        NavigateApps ->
            (model, Navigation.newUrl (Route.construct Route.Apps))
        NavigateHome ->
            (model, Navigation.newUrl (Route.construct Route.Home))


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
            Just (Route.App id) ->
                h3 [] [ text ("App single view for " ++ id) ]
            Just Route.Apps ->
                Html.map AppMsg (App.view model.appModel)
            Just Route.Home ->
                h3 [] [ text "You are home now." ]
    in
        div [ class "content" ]
            [ viewContainer (header [])
                [ viewHeader
                , nav [] [ span [] [ text model.zone ] ]
                ]
            , viewContext model
            , viewContainer (section [ class "highlight" ]) [ content ]
            , viewContainer (footer []) [ viewDebug model ]
            ]

viewContext : Model -> Html Msg
viewContext model =
    let
        (sectionClass, info) =
            case model.appModel.selected of
                Nothing ->
                    ("", span [] [])
                Just app ->
                    ("selected", viewAppSelected app)

    in
        viewContainer (section [ class sectionClass, id "context" ])
            [ h2 []
                [ a [ onClick NavigateApps, title "Apps" ]
                    [ span [ class "icon nc-icon-glyph ui-2_layers" ] []
                    , span [] [ text "Apps" ]
                    ]
                ]
            , info
            ]

viewAppSelected : App.App -> Html Msg
viewAppSelected app =
    nav []
        [ a [ onClick (NavigateApp app.id), title app.name ]
            [ span [] [ text app.name ]
            ]
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
        [ a [ onClick NavigateHome, title "Home" ]
            [ strong [] [ text "SocialPath" ]
            , span [] [ text "Console" ]
            ]
        ]

-- ROUTING

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
