local todo = require('todo-comments')

todo.setup {
    --[[ keywords = {
        TODO_AS = {icon = " ", color = "info"},
    }, ]]
    highlight = {
        pattern = [[.*<(KEYWORDS)\s*: AS\s-\s]],
    }
}
