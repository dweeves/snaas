module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, href, placeholder, title, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as Decode
import Json.Encode as Encode

-- MODEL

type alias App =
    { backend_token : String
    , description : String
    , enabled : Bool
    , name : String
    , token : String
    }

type alias Model =
    { apps : List App
    , description : String
    , name : String
    }

init : (Model, Cmd Msg)
init =
    (initModel, getList)

initModel : Model
initModel =
    Model [] "" ""

-- UPDATE

type Msg
    = AppList (Result Http.Error (List App))
    | Description String
    | Name String
    | New (Result Http.Error App)
    | Submit

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        AppList (Ok apps) ->
            ({ model | apps = apps }, Cmd.none)
        AppList (Err _) ->
            (model, Cmd.none)
        Description description ->
            ({ model | description = description }, Cmd.none)
        Name name ->
            ({ model | name = name }, Cmd.none)
        New (Ok app) ->
            ({ model | apps = model.apps ++ [ app ], description = "", name = "" }, Cmd.none)
        New (Err _) ->
            (model, Cmd.none)
        Submit ->
            (model, create model.name model.description)


-- VIEW

view : Model -> Html Msg
view model =
    div []
        [ viewList model.apps
        , viewForm model
        ]

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
        tr []
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
    Decode.map5 App
        (Decode.field "backend_token" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "enabled" Decode.bool)
        (Decode.field "name" Decode.string)
        (Decode.field "token" Decode.string)

decodeList : Decode.Decoder (List App)
decodeList =
    Decode.at [ "apps" ] (Decode.list decode)

encode : String -> String -> Http.Body
encode name description =
    Http.jsonBody (Encode.object [ ("name", Encode.string name), ("description", Encode.string description) ] )

getList : Cmd Msg
getList =
    Http.send AppList (Http.get "/api/apps" decodeList)