module Route exposing (Route(..), name, parser)

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)



-- MODEL


type Route
    = Home
    | About
    | Contact
    | NotFound Url


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map About (Parser.s "about")
        , Parser.map Contact (Parser.s "contact")
        ]



-- TITLE


name : Route -> Maybe String
name route =
    case route of
        Home ->
            Nothing

        About ->
            Just "About"

        Contact ->
            Just "Contact"

        NotFound _ ->
            Just "Not found"
