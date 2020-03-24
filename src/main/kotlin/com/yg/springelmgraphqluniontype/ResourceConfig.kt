package com.yg.springelmgraphqluniontype

import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer
import java.io.File


@Configuration
class ResourceConfig : WebMvcConfigurer {
    /**
     * Add a resource handler to load static resources from `dist` (where Parcel compiles the Elm code to).
     */
    override fun addResourceHandlers(registry: ResourceHandlerRegistry) {
        registry.addResourceHandler("*.html", "/*.js", "/*.js.map")
            .addResourceLocations(File("dist").toURI().toString())
            .setCachePeriod(0)
    }

    override fun addViewControllers(registry: ViewControllerRegistry) {
        registry.addViewController("/").setViewName("redirect:/index.html")
    }
}