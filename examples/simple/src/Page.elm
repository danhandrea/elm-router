module Page exposing (Page(..),Msg, init, subscriptions, update, view)

import Page.About as About
import Page.Contact as Contact
import Page.Home as Home
import Page.NotFound as NotFound
import Route exposing (Route(..))
import Router exposing (Layout)
import Url exposing (Url)


{-| Page
-}
type Page
    = Home
    | About
    | Contact Contact.Model
    | NotFound Url


{-| Msg
-}
type Msg
    = ContactMsg Contact.Msg


{-| init
-}
init : Route -> ( Page, Cmd Msg )
init route =
    case route of
        Route.Home ->
            ( Home, Cmd.none )

        Route.About ->
            ( About, Cmd.none )

        Route.Contact ->
            Contact.init "" ""
                |> Router.mapUpdate Contact ContactMsg

        Route.NotFound url ->
            ( NotFound url, Cmd.none )


{-| update
-}
update : Msg -> Page -> ( Page, Cmd Msg )
update message page =
    case message of
        ContactMsg msg ->
            case page of
                Contact mdl ->
                    Contact.update msg mdl
                        |> Router.mapUpdate Contact ContactMsg

                _ ->
                    ( page, Cmd.none )


{-| view
-}
view : Page -> Layout Msg
view page =
    case page of
        Home ->
            Home.view

        About ->
            About.view

        Contact mdl ->
            Contact.view mdl
                |> Router.mapView ContactMsg

        NotFound url ->
            NotFound.view url


{-| subscriptions
-}
subscriptions : Page -> Sub Msg
subscriptions page =
    case page of
        Home ->
            Sub.none

        About ->
            Sub.none

        Contact mdl ->
            Contact.subscriptions mdl
                |> Sub.map ContactMsg

        NotFound _ ->
            Sub.none
