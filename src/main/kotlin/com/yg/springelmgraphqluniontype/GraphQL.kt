package com.yg.springelmgraphqluniontype

import graphql.kickstart.tools.GraphQLQueryResolver
import graphql.kickstart.tools.SchemaParserDictionary
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.stereotype.Component

data class Size(val height: Int, val weight: Int)

sealed class Animal

data class Dog(val id: String, val name: String, val size: Size) : Animal()

data class Cat(val id: String, val name: String, val size: Size) : Animal()

@Component
class GraphQLQuery : GraphQLQueryResolver {
    fun animals(): List<Animal> = listOf(
        Cat("T", "Tom", Size(10, 5)),
        Dog("S", "Spike", Size(30, 20))
    )
}

@Configuration
class GraphQLConfiguration {
    @Bean
    fun parserDictionary(): SchemaParserDictionary = SchemaParserDictionary().add(
        mapOf(
            "Cat" to Cat::class.java,
            "Dog" to Dog::class.java
        )
    )
}