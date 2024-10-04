platform "glue"
    requires {} { main : _ }
    exposes []
    packages {}
    imports []
    provides [mainForHost]

# https://github.com/lukewilliamboswell/basic-ssg/blob/main/platform/main-glue.roc

SomeType : [Hello, World, Two]

mainForHost : SomeType
mainForHost = main
