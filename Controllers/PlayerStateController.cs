using Microsoft.AspNetCore.Mvc;
using System.Data;
using Microsoft.Data.SqlClient;
using Dapper;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Azure.SQLDB.Samples.Controllers;

[ApiController]
[Route("[controller]")]
public class PlayerStateController : ControllerBase
{
        private readonly ILogger<PlayerStateController> _logger;
        private readonly IConfiguration _config;

        public PlayerStateController(IConfiguration config, ILogger<PlayerStateController> logger)
        {
            _logger = logger;
            _config = config;
        }        

        private async Task<JObject> ExecuteProcedure(string verb, Guid id, JObject payload)
        {
            JObject result = new JObject();

            using (var conn = new SqlConnection(_config.GetConnectionString("ReadWriteConnection")))
            {
                DynamicParameters parameters = new DynamicParameters();
                parameters.Add("id", id.ToString());                
                if (payload != null) parameters.Add("payload", payload.ToString(Formatting.None));                

                var queryResult = await conn.ExecuteScalarAsync<string>(
                    sql: $"api.{verb}_player_data",
                    param: parameters,
                    commandType: CommandType.StoredProcedure
                );

                if (!string.IsNullOrEmpty(queryResult)) 
                    result = JObject.Parse(queryResult);
            }

            return result;            
        }

        [HttpGet]
        [Route("{id}")]
        public async Task<JObject> Get(Guid id)
        {
            return await ExecuteProcedure("get", id: id, payload: null);            
        }

        [HttpPut]    
        [Route("{id}")]    
        public async Task<JObject> Put(Guid id, [FromBody]JObject body)
        {
            return await ExecuteProcedure("put", id: id, payload: JObject.FromObject(body));                                
        }
}
