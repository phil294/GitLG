import { show_error_message, show_information_message } from './bridge.coffee'
import { createApp } from 'vue'
import './globals'
import App from './App.vue'
import PromiseForm from './components/PromiseForm.vue'
import Popup from './components/Popup.vue'
import moveable from './directives/moveable'
import drag from './directives/drag'
import drop from './directives/drop'
import context_menu from './directives/context-menu'
import { RecycleScroller } from 'vue-virtual-scroller'
import 'vue-virtual-scroller/dist/vue-virtual-scroller.css'
import '@vscode/codicons/dist/codicon.css'

console_error = console.error
handle_error = (###* @type {any} ### e) =>
    console_error e, new Error().stack
    console.trace()
    debugger
    show_error_message "git log --graph extension encountered an unexpected error. Sorry! Error summary: " + (e.message or e.msg or e.data or e.body or e.stack or try JSON.stringify(e) or e.toString?()) + ". For details, see VSCode developer console. Please consider reporting this error."
window.onerror = handle_error
console.error = handle_error
window.addEventListener 'unhandledrejection', (e) =>
    handle_error e.reason

window.alert = show_information_message

app = createApp(App)

app.config.errorHandler = handle_error
app.config.warnHandler = handle_error

app.component 'promise-form', PromiseForm
app.component 'popup', Popup
app.component 'recycle-scroller', RecycleScroller
app.directive 'moveable', moveable
app.directive 'drag', drag
app.directive 'drop', drop
app.directive 'context-menu', context_menu

app.mount('#app')