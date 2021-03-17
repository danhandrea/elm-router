module Route exposing (Route(..), parser)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)



-- ROUTE


type Route
    = Home
    | About
    | Contact String String
    | NotFound Url



-- PARSER


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map About (Parser.s "about")
        , Parser.map Contact (Parser.s "contact" </> Parser.string </> Parser.string)
        ]
