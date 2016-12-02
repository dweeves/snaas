module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, href, placeholder, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Navigation

import Container
import Route

-- MODEL

type alias App =
    { backend_token : String
    , description : String
    , enabled : Bool
    , id : String
    , name : String
    , token : String
    }

type alias Context =
    { model : Model
    , route : Maybe Route.Route
    }

type alias Model =
    { apps : List App
    , description : String
    , name : String
    , selected : (Maybe App)
    }

init : Maybe Route.Route -> (Model, Cmd Msg)
init route =
    case route of
        Just (Route.App id) ->
            (initModel, getApp id)
        Just Route.Apps ->
            (initModel, getApps)
        _ ->
            (initModel, Cmd.none)

initApp : App
initApp =
    App "" "" False "" "" ""

initModel : Model
initModel =
    Model [] "" "" Nothing

-- UPDATE

type Msg
    = FetchApp (Result Http.Error App)
    | FetchApps (Result Http.Error (List App))
    | Description String
    | Name String
    | New (Result Http.Error App)
    | Select String
    | Submit

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        FetchApp (Ok app) ->
            ({ model | selected = (Just app) }, Cmd.none)
        FetchApp (Err _) ->
            (model, Cmd.none)
        FetchApps (Ok apps) ->
            ({ model | apps = apps, selected = Nothing }, Cmd.none)
        FetchApps (Err _) ->
            (model, Cmd.none)
        Description description ->
            ({ model | description = description }, Cmd.none)
        Name name ->
            ({ model | name = name }, Cmd.none)
        New (Ok app) ->
            ({ model | apps = model.apps ++ [ app ], description = "", name = "" }, Cmd.none)
        New (Err _) ->
            (model, Cmd.none)
        Select id ->
            ({ model | selected = (selectApp id model.apps) }, Navigation.newUrl (Route.construct (Route.App id)))
        Submit ->
            (model, create model.name model.description)


-- VIEW

view : Context -> Html Msg
view {model, route} =
    case route of
        Just (Route.Apps) ->
            Container.view (section [ class "highlight" ])
                [ viewList model.apps
                , viewForm model
                ]
        Just (Route.App _) ->
            Container.view (section [])
                [ viewApp model
                ]
        _ ->
           div [] []

viewApp : Model -> Html Msg
viewApp {selected} =
    let
        app = Maybe.withDefault (initApp) selected
    in
        h3 [] [ text ("App single view for " ++ app.name) ]

viewForm : Model -> Html Msg
viewForm model =
    form [ onSubmit Submit ]
        [ input
            [ onInput Name
            , placeholder "Name"
            , type_ "text"
            , value model.name
            ] []
        , input
            [ class "description"
            , onInput Description
            , placeholder "Description"
            , type_ "text"
            , value model.description
            ] []
        , button [ type_ "submit" ] [ text "Create" ]
        ]

viewItem : App -> Html Msg
viewItem app =
    let
        enabled = if app.enabled then
                span [ class "nc-icon-glyph ui-1_check-circle-07" ] []
            else
                span [ class "nc-icon-glyph ui-1_circle-remove" ] []
    in
        tr [ onClick (Select app.id) ]
            [ td [ class "status" ] [ enabled ]
            , td [] [ text app.name ]
            , td [] [ text app.description ]
            , td [] [ text app.token ]
            ]

viewList : List App -> Html Msg
viewList apps =
    if List.length apps == 0 then
        h3 [] [ text "Looks like you haven't created an App yet." ]
    else
        table []
            [ thead []
                [ tr []
                    [ th [ class "status" ] [ text "status" ]
                    , th [] [ text "name" ]
                    , th [] [ text "description" ]
                    , th [] [ text "token" ]
                    ]
                ]
            , tbody [] (List.map viewItem apps)
            ]

-- HTTP

create : String -> String -> Cmd Msg
create name description =
    Http.post "/api/apps" (encode name description) decode
    |> Http.send New

decode : Decode.Decoder App
decode =
    Decode.map6 App
        (Decode.field "backend_token" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "enabled" Decode.bool)
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "token" Decode.string)

decodeList : Decode.Decoder (List App)
decodeList =
    Decode.at [ "apps" ] (Decode.list decode)

encode : String -> String -> Http.Body
encode name description =
    Http.jsonBody (Encode.object [ ("name", Encode.string name), ("description", Encode.string description) ] )

getApp : String -> Cmd Msg
getApp id =
    Http.send FetchApp (Http.get ("/api/apps/" ++ id) decode)

getApps : Cmd Msg
getApps =
    Http.send FetchApps (Http.get "/api/apps" decodeList)

selectApp : String -> List App -> Maybe App
selectApp id apps =
    apps
    |> List.filter (\app -> app.id == id)
    |> List.head
