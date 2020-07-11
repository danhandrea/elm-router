module Route exposing (Msg, Route, notFound, parser, subscriptions, title, update, view)

import Html as H exposing (Html)
import Page.About as About
import Page.Contact as Contact
import Page.Home as Home
import Router
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)



-- MODEL


type Route
    = Home
    | About
    | Contact Contact.Model



-- MSG


type Msg
    = ContactMsg Contact.Model Contact.Msg



-- PARSER


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Router.mapRoute Parser.top Home
        , Router.mapRoute (Parser.s "about") About
        , Router.mapRoute (Parser.s "contact") <| Contact <| Contact.init "" ""
        ]



-- UPDATE


update : Msg -> ( Route, Cmd Msg )
update message =
    case message of
        ContactMsg model msg ->
            Contact.update msg model
                |> Router.mapUpdate Contact ContactMsg



-- VIEW


view : Route -> List (Html Msg)
view route =
    case route of
        Home ->
            Home.view

        About ->
            About.view

        Contact mdl ->
            Contact.view mdl
                |> Router.mapMsg (ContactMsg mdl)



-- SUBSCRIPTIONS


subscriptions : Route -> Sub Msg
subscriptions route =
    case route of
        Home ->
            Sub.none

        About ->
            Sub.none

        Contact mdl ->
            Contact.subscriptions mdl
                |> Sub.map (ContactMsg mdl)



-- TITLE


title : Route -> Maybe String
title route =
    case route of
        Home ->
            Nothing

        About ->
            Just "About"

        Contact _ ->
            Just "Contact"



-- NOT FOUND


notFound : Url -> List (Html msg)
notFound url =
    [ H.h1 [] [ H.text "Page not found!" ]
    , H.h3 [] [ H.text <| Url.toString url ]
    ]
