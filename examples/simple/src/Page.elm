module Page exposing (Msg(..), Page(..), init, subscriptions, update, view)

import Html exposing (Html)
import Page.About as About
import Page.Contact as Contact
import Page.Home as Home
import Page.NotFound as NotFound
import Route exposing (Route)
import Router


type Page
    = Home
    | About
    | Contact Contact.Model
    | NotFound NotFound.Model


type Msg
    = ContactMsg Contact.Model Contact.Msg


init : Route -> ( Page, Cmd Msg )
init route =
    case route of
        Route.Home ->
            ( Home, Cmd.none )

        Route.About ->
            ( About, Cmd.none )

        Route.Contact name email ->
            Contact.init name email
                |> Router.map Contact ContactMsg

        Route.NotFound url ->
            ( NotFound <| NotFound.init url, Cmd.none )



-- UPDATE


update : Msg -> ( Page, Cmd Msg )
update message =
    case message of
        ContactMsg model msg ->
            Contact.update msg model
                |> Router.map Contact ContactMsg



-- VIEW


view : Page -> Html Msg
view page =
    case page of
        Home ->
            Home.view

        About ->
            About.view

        Contact mdl ->
            Contact.view mdl
                |> Html.map (ContactMsg mdl)

        NotFound mdl ->
            NotFound.view mdl


subscriptions : Page -> Sub Msg
subscriptions page =
    case page of
        Home ->
            Sub.none

        About ->
            Sub.none

        Contact mdl ->
            Contact.subscriptions mdl
                |> Sub.map (ContactMsg mdl)

        NotFound _ ->
            Sub.none
