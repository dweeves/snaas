module Route exposing (..)

import Navigation exposing (Location, newUrl)
import UrlParser exposing (Parser, (</>), map, oneOf, parsePath, top, s, string)

-- MODEL

type alias Model =
    { current : Maybe Route
    }

type Route
    = App String
    | Apps
    | Dashboard
    | Members

init : Location -> (Model, Cmd Msg)
init location =
    (Model (parse location), Cmd.none)

--  UPDATE

type Msg
    = Change Location

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Change location ->
            ({ model | current = (parse location) }, Cmd.none)

-- HELPER

construct : Route -> String
construct route =
    case route of
        App id ->
            "/apps/" ++ id
        Apps ->
            "/apps"
        Dashboard ->
            "/"
        Members ->
            "/members"

navigate : Route -> Cmd Msg
navigate route =
    newUrl (construct route)

parse : Location -> Maybe Route
parse location =
    parsePath routes location

routes : Parser (Route -> a) a
routes =
    oneOf
        [ map Dashboard top
        , map App (s "apps" </> string)
        , map Apps (s "apps")
        , map Members (s "members")
        ]
