@ECHO OFF
SET MAVEN_HOME=%USERPROFILE%\.m2\wrapper\dists\apache-maven-3.9.6-bin\3311e1d4\apache-maven-3.9.6
SET MAVEN_CMD=%MAVEN_HOME%\bin\mvn.cmd

IF NOT EXIST "%MAVEN_CMD%" (
    ECHO Baixando Maven...
    java "-Dmaven.multiModuleProjectDirectory=%CD%" -cp ".mvn\wrapper\maven-wrapper.jar" org.apache.maven.wrapper.MavenWrapperMain %*
) ELSE (
    "%MAVEN_CMD%" -Dmaven.multiModuleProjectDirectory="%CD%" %*
)
