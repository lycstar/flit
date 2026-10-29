group = "cc.lycstar.flit.lsp"
version = "1.0"

plugins {
    id("com.android.library")
}

android {
    namespace = "cc.lycstar.flit.lsp"
    compileSdk = 36

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

// 与 app 一致: builtInKotlin=false 时 KGP 由 Flutter Gradle 插件自动应用, 这里只对齐 JVM 目标
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
