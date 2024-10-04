platform "host"
    requires {} { main : Task {} {} }
    exposes [
    ]
    packages {
    }
    imports []
    provides [mainForHost]

mainForHost : Task {} {}
mainForHost = main
