module Console exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, href, id, placeholder, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Navigation

import App
import Container
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
    , route : Route.Model
    , zone : String
    }

init : Flags -> Navigation.Location -> (Model, Cmd Msg)
init {zone} location =
    let
        (routeModel, routeCmd) = Route.init location
        (appModel, appCmd) = App.init routeModel.current
    in
        (Model appModel routeModel zone) !
            [ Cmd.map RouteMsg routeCmd
            , Cmd.map AppMsg appCmd
            ]

-- UPDATE

type Msg
    = AppMsg App.Msg
    | LocationChange Navigation.Location
    | Navigate Route.Route
    | RouteMsg Route.Msg

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
                (routeModel, routeCmd) = Route.update (Route.Change location) model.route
            in
                ({ model | route = routeModel }, Cmd.map RouteMsg routeCmd)
        Navigate route ->
            (model, Cmd.map RouteMsg (Route.navigate route))
        RouteMsg routeMsg ->
            let
                (routeModel, routeCmd) = Route.update routeMsg model.route
            in
                ({ model | route = routeModel }, Cmd.map RouteMsg routeCmd)


-- SUBSCRIPTION

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- VIEW

view : Model -> Html Msg
view model =
    let
        page = case model.route.current of
            Nothing ->
                [ viewNotFound ]
            Just (Route.App id) ->
                [ viewAppContext model.appModel
                , viewApp model
                ]
            Just Route.Apps ->
                [ viewAppContext model.appModel
                , viewApp model
                ]
            Just Route.Dashboard ->
                [ viewDashboard ]
            Just Route.Members ->
                [ viewNotFound ]
    in
        div [ class "content" ]
            [ viewHeader model
            , div [] page
            , viewFooter model
            ]

viewApp : Model -> Html Msg
viewApp {appModel, route} =
    Html.map AppMsg (App.view (App.Context appModel route.current))

viewAppContext : App.Model -> Html Msg
viewAppContext model =
    let
        (sectionClass, info) =
            case model.selected of
                Nothing ->
                    ("", span [] [])
                Just app ->
                    ("selected", viewAppSelected app)

    in
        Container.view (section [ class sectionClass, id "context" ])
            [ h2 []
                [ a [ onClick (Navigate Route.Apps), title "Apps" ]
                    [ span [ class "icon nc-icon-glyph ui-2_layers" ] []
                    , span [] [ text "Apps" ]
                    ]
                ]
            , info
            ]

viewAppSelected : App.App -> Html Msg
viewAppSelected app =
    nav []
        [ a [ onClick (Navigate (Route.App app.id)), title app.name ]
            [ span [] [ text app.name ]
            , span [ class "icon nc-icon-outline arrows-2_skew-down" ] []
            ]
        ]

viewDashboard : Html Msg
viewDashboard =
    Container.view (section [ id "dashboard" ])
        [ h2 []
            [ text "Hej, start of by looking into"
            , a [ onClick (Navigate Route.Apps), title "Apps" ]
                [ span [ class "icon nc-icon-glyph ui-2_layers" ] []
                , text "Apps"
                ]
            , text "or"
            , a [ onClick (Navigate Route.Members), title "Members" ]
                [ span [ class "icon nc-icon-glyph users_multiple-11" ] []
                , text "Members"
                ]
            ]
        ]

viewDebug : Model -> Html Msg
viewDebug model =
    div [ class "debug" ]
      [ text (toString model)
      ]

viewFooter : Model -> Html Msg
viewFooter model=
    Container.view (footer []) [ viewDebug model ]

viewHeader : Model -> Html Msg
viewHeader model =
    Container.view (header [])
        [ h1 []
            [ a [ onClick (Navigate Route.Dashboard), title "Home" ]
                [ strong [] [ text "SocialPath" ]
                , span [] [ text "Console" ]
                ]
            ]
        , nav [] [ span [] [ text model.zone ] ]
        ]

viewNotFound : Html Msg
viewNotFound =
    Container.view (section [ class "highlight" ])
        [ h3 [] [ text "Looks like we couldn't find the page you were looking for." ]
        ]