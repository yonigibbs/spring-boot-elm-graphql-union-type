import com.moowork.gradle.node.npm.NpmTask
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("org.springframework.boot") version "2.2.5.RELEASE"
    id("io.spring.dependency-management") version "1.0.9.RELEASE"
    kotlin("jvm") version "1.3.70"
    kotlin("plugin.spring") version "1.3.70"
    id("com.github.node-gradle.node") version "2.2.3"
    idea
}

group = "com.yg"
version = "0.0.1"
java.sourceCompatibility = JavaVersion.VERSION_1_8

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("com.graphql-java-kickstart:graphql-spring-boot-starter:7.0.0")
    runtimeOnly("com.graphql-java-kickstart:playground-spring-boot-starter:7.0.0")
    testImplementation("org.springframework.boot:spring-boot-starter-test") {
        exclude(group = "org.junit.vintage", module = "junit-vintage-engine")
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.withType<KotlinCompile> {
    kotlinOptions {
        freeCompilerArgs = listOf("-Xjsr305=strict")
        jvmTarget = "1.8"
    }
}

idea {
    module {
        sourceDirs = setOf(file("src/main/elm"))
    }
}

val elmFolder = file("src/main/elm")
val packageJson = file("package.json")
val elmJson = file("elm.json")
val distFolder = file("dist")

task<NpmTask>("buildElm") {
    setArgs(listOf("run", "build"))
    this.group = "build"
    dependsOn("npmInstall")
    inputs.dir(file("src/main/elm"))
    inputs.files(file("package.json"), file("elm.json"))
    listOf("bootRun", "build").forEach {
        tasks.getByName(it).dependsOn(this)
    }
    outputs.dir(file("dist"))
}

// Configure the clean task for this project so that it cleans the frontend/dist folder too.
tasks.getByName<Delete>("clean") {
    delete(distFolder)
}
