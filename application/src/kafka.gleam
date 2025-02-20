import gleam/io
import gleam/result
import gleam/string
import gleam/list
import gleam/option
import gleam/map
import gleam/time
import gleam/uri

import beam.{Pipeline, Create, Map, Write, ParDo}
import beam/runners/direct
import beam/coders
import beam/options

// Erlang interop for calling KafkaEx functions
@external(erlang, "kafka_ex", "consume", ["binary", "binary", "list"])
pub fn kafka_ex_consume(topic: String, broker: String, options: List(#(String, String))) -> Result(List(#(String, String)), String)

pub fn main() -> Result(Nil, String) {
  let options =
    options.new(from_list([#("runner", "direct"), #("streaming", "false")])) // Streaming doesn't work with batch reads.

  let! pipeline = Pipeline.new(options)

  // Kafka Configuration
  let brokers = "localhost:9092" // Adjust to your Kafka brokers
  let topic = "my-topic"        // Adjust to your Kafka topic

  // ***********************************************************************
  // Create a source that reads from Kafka using KafkaEx (Erlang interop)
  // ***********************************************************************
  let kafka_source =
    consume_from_kafkaex(topic, brokers)

  // If we couldn't read from kafka, return an error
  let! kafka_messages =
    kafka_source

  // Create a Beam source from the Kafka messages.
  let source = pipeline
  |> Create.strings(from: list.map(kafka_messages, fn(message) {
    // Extract the value from the key-value pair.  Assuming the value is the actual message.
    #(message.1)
  }))

  // Transform the data (example: convert to uppercase)
  let uppercase =
    source
    |> Map.strings(string.to_uppercase)

  // Print the transformed data to the console
  let sink =
    uppercase
    |> ParDo.string(fn(element) {
      io.println(element)
      Ok(Nil)
    })

  // Alternatively, write the data to a file
  // let sink =
  //   uppercase
  //   |> Write.to_text("output.txt") // Adjust filename as needed

  // Run the pipeline
  direct.run(pipeline)
  |> result.map(fn(_) { io.println("Pipeline finished successfully.") })
}

// Helper function to encapsulate the KafkaEx consumption
fn consume_from_kafkaex(topic: String, broker: String) -> Result(List(#(String, String)), String) {
  let options =
    [#("offset", "earliest")]

  kafka_ex_consume(topic, broker, options)
}
