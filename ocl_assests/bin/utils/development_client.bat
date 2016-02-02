SET config_file=./debug_client_session.conf
REM Add the jar files needed to find jars implemented by views
SET views_path=../../examples/signal_generator_gui/code/*

java -cp %views_path%;..\..\lib\client\RELATEDClient.jar;..\..\lib\log4j-1.2.16.jar;..\..\lib\gson-2.2.3.jar;..\..\lib\RLABCServerProject.jar;..\..\lib\jfreechart-1.0.14.jar;..\..\lib\jcommon-1.0.17.jar;..\..\lib\jaxb-ws\jaxws-rt.jar;..\..\lib\jaxb-ws\streambuffer.jar;..\..\lib\jaxb-ws\policy.jar;..\..\lib\jaxb-ws\jaxb-impl.jar;..\..\lib\stax-ex.jar;..\..\lib\gmbal-api-only.jar es.uned.scc.related.client.RlabSysWindow %config_file%