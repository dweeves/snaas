module Console exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, href, id, placeholder, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Navigation

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
    , route : Route.Model
    , zone : String
    }

type alias Tag = List (Html Msg) -> Html Msg

init : Flags -> Navigation.Location -> (Model, Cmd Msg)
init {zone} location =
    let
        (routeModel, _) = Route.init location

        (appModel, appCmd) = App.init
    in
        (Model appModel routeModel zone, Cmd.map AppMsg appCmd)

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
        content = case model.route.current of
            Nothing ->
                [ viewNotFound ]
            Just (Route.App id) ->
                [ viewContext model
                , viewContainer (section [])
                    [ Html.map AppMsg (App.viewApp model.appModel id)
                    ]
                ]
            Just Route.Apps ->
                [ viewContext model
                , viewContainer (section [ class "highlight" ])
                    [ Html.map AppMsg (App.view model.appModel)
                    ]
                ]
            Just Route.Dashboard ->
                [ viewDashboard ]
            Just Route.Members ->
                [ viewNotFound ]
    in
        div [ class "content" ]
            (List.concat
                [ [ viewHeader model ]
                , content
                , [ viewFooter model ]
                ])

viewAppSelected : App.App -> Html Msg
viewAppSelected app =
    nav []
        [ a [ onClick (Navigate (Route.App app.id)), title app.name ]
            [ span [] [ text app.name ]
            , span [ class "icon nc-icon-outline arrows-2_skew-down" ] []
            ]
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
                [ a [ onClick (Navigate Route.Apps), title "Apps" ]
                    [ span [ class "icon nc-icon-glyph ui-2_layers" ] []
                    , span [] [ text "Apps" ]
                    ]
                ]
            , info
            ]

viewContainer : Tag -> List (Html Msg) -> Html Msg
viewContainer elem content =
    elem
        [ div [ class "container" ]
            content
        ]

viewDashboard : Html Msg
viewDashboard =
    viewContainer (section [])
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
    viewContainer (footer []) [ viewDebug model ]

viewHeader : Model -> Html Msg
viewHeader model =
    viewContainer (header [])
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
    viewContainer (section [ class "highlight" ])
        [ h3 [] [ text "Looks like we couldn't find the page you were looking for." ]
        ]