local todo = require('todo-comments')

todo.setup {
    highlight = {
        keyword = 'fg',
        pattern = [[.*<(KEYWORDS)(\([^\)]*\))?:]],
    },
    search = {
        pattern = [[\b(KEYWORDS)(\([^\)]*\))?:]],
    }
}
