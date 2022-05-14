import { ref } from 'vue'

#
###* @type {import('vscode-webview').WebviewApi<unknown>} ###
vscode = acquireVsCodeApi?() or
    # fallback for developing in browser
    postMessage: ({ command }) =>
        # alert "post message #{command}"
    getState: =>
    setState: (_) => _

store =
    error: ref ''
    ready: =>
        vscode.postMessage command: 'ready'
    commits: ref ['foo']

window.addEventListener 'message', (event) =>
    message = event.data
    switch message.command
        when 'commits'
            store.commits.value = message.data

export default store