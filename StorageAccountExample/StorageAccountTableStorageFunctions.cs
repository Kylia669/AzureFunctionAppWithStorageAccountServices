using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Azure;

namespace StorageAccountExample
{
    internal class StorageAccountTableStorageFunctions
    {
        private const string BlobConnection = "blobConnection";
        private const string TableName = "table";
        private ILogger<StorageAccountTableStorageFunctions> _logger;

        public StorageAccountTableStorageFunctions(ILogger<StorageAccountTableStorageFunctions> logger)
        {
            _logger = logger;
        }

        [FunctionName("TableInput")]
        public async Task<IActionResult> BlobTriggerAsync([HttpTrigger(AuthorizationLevel.Anonymous, "GET", Route = "table-get/{partition}/{id}")] string id,
            [Table(TableName, "{partition}", "{id}")] TableEntity item)
        {
            return new OkObjectResult(item);
        }

        [FunctionName("TableOutput")]
        [return: Table(TableName, Connection = BlobConnection)]
        public TableEntity BlobOutputAsync([HttpTrigger(AuthorizationLevel.Anonymous, "POST", Route = "queue-add")] TableEntity message)
        {
            _logger.LogInformation($"Table item added: {message.Name}");
            return message;
        }

        public class TableEntity : Azure.Data.Tables.ITableEntity
        {
            public string Name { get; set; }
            public string PartitionKey { get; set; }
            public string RowKey { get; set; }
            public DateTimeOffset? Timestamp { get; set; }
            public ETag ETag { get; set; }
        }
    }
}
