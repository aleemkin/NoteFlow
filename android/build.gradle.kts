allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    val configureCompileSdk = {
        project.extensions.findByName("android")?.let { ext ->
            val cls = ext.javaClass
            val methods = cls.methods.filter {
                it.name in listOf("setCompileSdk", "setCompileSdkVersion", "compileSdkVersion") &&
                it.parameterCount == 1
            }
            for (m in methods) {
                try {
                    val paramType = m.parameterTypes[0]
                    if (paramType == Int::class.javaPrimitiveType || paramType == java.lang.Integer::class.java) {
                        m.invoke(ext, 36)
                        break
                    }
                } catch (_: Exception) {}
            }
        }
    }

    if (project.state.executed) {
        configureCompileSdk()
    } else {
        project.afterEvaluate { configureCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
