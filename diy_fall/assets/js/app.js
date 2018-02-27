import "phoenix_html"

const Elm = require('./main')

const container = document.querySelector("#elm-container")
Elm.Main.embed(container)
