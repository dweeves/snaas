module Console exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, href, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Navigation
import UrlParser as Url exposing ((</>), (<?>), s, int, stringParam, top)

main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


-- MODEL

type alias App =
    { backend_token : String
    , description : String
    , enabled : Bool
    , name : String
    , token : String
    }

type alias Flags =
    { zone : String
    }

type alias Model =
    { apps : List App
    , debug : Bool
    , description : String
    , name : String
    , zone : String
    }

type Page
    = NotFound
    | AppList

type alias Tag = List (Html Msg) -> Html Msg

init : Flags -> Navigation.Location -> (Model, Cmd Msg)
init {zone} location =
    (Model [] (isDebug location) "" "" zone, getApps)

-- UPDATE

type Msg
    = Apps (Result Http.Error (List App))
    | Description String
    | Name String
    | NewApp (Result Http.Error App)
    | Submit
    | UrlChange Navigation.Location

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Apps (Ok apps) ->
            ({ model | apps = apps }, Cmd.none)
        Apps (Err _) ->
            (model, Cmd.none)
        Description description ->
            ( { model | description = description }, Cmd.none)
        Name name ->
            ( { model | name = name }, Cmd.none)
        NewApp (Ok app) ->
            ( { model | apps = model.apps ++ [ app ], description = "", name = "" }, Cmd.none)
        NewApp (Err _) ->
            (model, Cmd.none)
        Submit ->
            (model, createApp model.name model.description)
        UrlChange location ->
            ( { model | debug = isDebug location }, Cmd.none)

-- SUBSCRIPTION

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- VIEW

view : Model -> Html Msg
view model =
    div [ class "content" ]
        [ viewContainer (header [])
            [ viewHeader
            , nav [] [ span [] [ text model.zone ] ]
            ]
        , viewContainer (section [])
            [ h2 []
                [ div [ class "icon nc-icon-glyph ui-2_layers" ] []
                , a [ href "/apps" ] [ text "Apps" ]
                ]
            ]
        , viewContainer (section [ class "highlight" ])
            [ viewApps model.apps
            , viewForm model
            ]
        , viewContainer (footer []) [ viewDebug model ]
        ]

viewApps : List App -> Html Msg
viewApps apps =
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
                    , th [] [ text "backend token" ]
                    ]
                ]
            , tbody [] (List.map viewAppItem apps)
            ]

viewAppItem : App -> Html Msg
viewAppItem app =
    let
        enabled = if app.enabled then
                span [ class "nc-icon-glyph ui-1_check-circle-07" ] []
            else
                span [ class "nc-icon-glyph ui-1_circle-remove" ] []
    in
        tr []
            [ td [ class "status" ] [ enabled ]
            , td [] [ text app.name ]
            , td [] [ text app.description ]
            , td [] [ text app.token ]
            , td [] [ text app.backend_token ]
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
        [ a [ href "/" ]
            [ strong [] [ text "SocialPath" ]
            , span [] [ text "Console" ]
            ]
        ]

viewForm : Model -> Html Msg
viewForm model =
    form [ onSubmit Submit ]
        [ input [ type_ "text", placeholder "Name", onInput Name, value model.name ] []
        , input
            [ class "description"
            , type_ "text"
            , placeholder "Description"
            , onInput Description
            , value model.description
            ] []
        , button [ type_ "submit" ] [ text "Create" ]
        ]

-- HTTP

createApp : String -> String -> Cmd Msg
createApp name description =
    Http.post "/api/apps" (Http.jsonBody (Encode.object [ ("name", Encode.string name), ("description", Encode.string description) ] )) decodeApp
        |> Http.send NewApp

getApps : Cmd Msg
getApps =
    Http.send Apps (Http.get "/api/apps" decodeApps)

decodeApps : Decode.Decoder (List App)
decodeApps =
    Decode.at [ "apps" ] (Decode.list decodeApp)

decodeApp : Decode.Decoder App
decodeApp =
    Decode.map5 App
        (Decode.field "backend_token" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "enabled" Decode.bool)
        (Decode.field "name" Decode.string)
        (Decode.field "token" Decode.string)

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
