"use strict";

exports.handler = async (event) => {
  const responseBody = {
    hello: "world",
  };

  const response = {
    statusCode: 200,
    headers: {
      "x-custom-header": "my custom header value",
    },
    body: JSON.stringify(responseBody),
  };

  return response;
};
