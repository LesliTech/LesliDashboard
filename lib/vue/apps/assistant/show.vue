<script setup>

import { ref, onMounted } from "vue";
import { useLayout } from "Lesli/vue/shared/stores/layout.js"

const storeLayout = useLayout()

const lesli = Lesli;
const hour = new Date().getHours();
const welcomeTypes = ["Good morning", "Good afternoon", "Good evening"];
const welcomeText = ref("");

import dayjs from "dayjs"


onMounted(()=>{
    if (hour < 12) {
        welcomeText.value = welcomeTypes[0]
    } else if (hour < 18) {
        welcomeText.value = welcomeTypes[1]
    } else {
        welcomeText.value = welcomeTypes[2]
    }
})

</script>
<template>
    <lesli-application-container>
        <section class="lesli-element-header is-flex mt-6">
            <div class="lesli-element-header-title">
                <h1 class="subtitle is-size-3 mb-0">{{welcomeText}}, {{ lesli.current_user?.name }}</h1>
                <p class="">{{ dayjs().format("dddd, MMMM D") }}.</p>
            </div>
        </section>
    </lesli-application-container>
</template>
