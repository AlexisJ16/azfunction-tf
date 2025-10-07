module.exports = async function (context, req) {
  context.log("JavaScript HTTP trigger function processed a request.");

  const name = req.query?.name ?? req.body?.name;

  const responseMessage = name
    ? { id: name, message: `Hola ${name}, tu función está activa.` }
    : "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.";

  context.res = {
    status: 200,
    headers: {
      "Content-Type": typeof responseMessage === "string" ? "text/plain" : "application/json",
    },
    body: responseMessage,
  };
};
