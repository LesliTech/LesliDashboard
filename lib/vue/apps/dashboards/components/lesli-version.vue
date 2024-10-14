<script setup>
/*
Lesli

Copyright (c) 2023, Lesli Technologies, S. A.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.

Lesli · Ruby on Rails SaaS Development Framework.

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
*/


// · 
import { onMounted, inject, ref } from "vue"


// · 
const url = inject("url")
const http = inject("http")


// · 
const lesliVersion = ref({
    name: "",
    code: "",
    path: "",
    version: "",
    build: ""
})


// · 
onMounted(() => {
    http.get(url.lesli("about")).then(result => {
        lesliVersion.value = result.find(engine => engine.name == "Lesli")
    }).catch(error => {
        console.log(error)
    })
})
</script>
<template>
    <lesli-card>
        <h6 class="title is-6 mb-2">
            {{ lesliVersion.name }}
        </h6>
        <p class="p-0 m-0">version: {{ lesliVersion.version }}</p>
        <p class="p-0 m-0">buid: {{ lesliVersion.build }}</p>
        <p class="p-0 m-0">path: {{ lesliVersion.path }}</p>
    </lesli-card>
</template>
