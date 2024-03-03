<script setup>


import { ref, onMounted } from "vue";

const lesli = Lesli;
const hour = new Date().getHours();
const welcomeTypes = ["Good morning", "Good afternoon", "Good evening"];
const welcomeText = ref("");


onMounted(()=>{
    if (hour < 12) {
        welcomeText.value = welcomeTypes[0]
    } else if (hour < 18) {
        welcomeText.value = welcomeTypes[1]
    } else {
        welcomeText.value = welcomeTypes[2]
    }
    //_lesli.value = lesli
})

</script>
<template>
    <lesli-application-container>
        <section class="lesli-element-header is-flex mt-6">
            <div class="lesli-element-header-title is-flex">
                <h1 class="subtitle is-3">{{welcomeText}},<br/>{{ lesli.current_user?.name }}</h1>
            </div>
        </section>
        
    </lesli-application-container>
</template>
