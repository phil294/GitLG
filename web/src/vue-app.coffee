import store from './store.coffee'
import { createApp } from 'vue'
import App from './App.vue'
import PromiseForm from './components/PromiseForm.vue'
import { RecycleScroller } from 'vue-virtual-scroller'
import 'vue-virtual-scroller/dist/vue-virtual-scroller.css'

app = createApp(App)

app.component 'promise-form', PromiseForm
app.component 'recycle-scroller', RecycleScroller

console_error = console.error
handle_error = (###* @type {any} ### e) =>
    console_error e
    store.show_error_message "git log --graph extension encountered an unexpected error. Sorry! Error summary: " + (e.message or e.msg or e.data or e.body or e.stack or e.status or e.name or e.toString?() or try JSON.stringify(e))
app.config.errorHandler = handle_error
app.config.warnHandler = handle_error
window.onerror = handle_error
console.error = handle_error
window.addEventListener 'unhandledrejection', (e) =>
    handle_error e.reason

window.alert = store.show_information_message

app.mount('#app')