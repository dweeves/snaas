module Route exposing (..)

import Navigation exposing (Location)
import UrlParser exposing (Parser, (</>), map, oneOf, parsePath, top, s, string)

type Route
    = App String
    | Apps
    | Home

construct : Route -> String
construct route =
    case route of
        App id ->
            "/apps/" ++ id
        Apps ->
            "/apps"
        Home ->
            "/"

routes : Parser (Route -> a) a
routes =
    oneOf
        [ map Home top
        , map App (s "apps" </> string)
        , map Apps (s "apps")
        ]

parse : Location -> (Maybe Route)
parse location =
    parsePath routes location
