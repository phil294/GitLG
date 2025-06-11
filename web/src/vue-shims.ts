declare module '@vue/runtime-core' {
    // TODO: https://github.com/vuejs/language-tools/issues/5420
    export interface AllowedComponentProps {
        [key: `data${string}`]: any
        id?: string;
    }
}

export default {}