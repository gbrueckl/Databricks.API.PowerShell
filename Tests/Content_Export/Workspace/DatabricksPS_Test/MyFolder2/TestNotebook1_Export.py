# Databricks notebook source
#widgets
#dbutils.widgets.removeAll()
dbutils.widgets.dropdown("throwError", "0", ["0", "1"])
throwError = bool(int(dbutils.widgets.get("throwError")))

# COMMAND ----------

if throwError:
  raise "Error"