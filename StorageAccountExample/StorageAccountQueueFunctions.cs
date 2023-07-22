using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace StorageAccountExample
{
    internal class StorageAccountQueueFunctions
    {
        private const string BlobConnection = "blobConnection";
        private const string QueueName = "queue";
        private ILogger<StorageAccountQueueFunctions> _logger;

        public StorageAccountQueueFunctions(ILogger<StorageAccountQueueFunctions> logger)
        {
            _logger = logger;
        }

        [FunctionName("QueueTrigger")]
        public void BlobTrigger([QueueTrigger(QueueName, Connection = BlobConnection)] QueueMessage message)
        {
            _logger.LogInformation($"Queue messaged: {message.Message}");
        }

        [FunctionName("QueueOutput")]
        [return: Queue(QueueName, Connection = BlobConnection)]
        public QueueMessage BlobOutputAsync([HttpTrigger(AuthorizationLevel.Anonymous, "POST", Route = "queue-add")] QueueMessage message)
        {
            _logger.LogInformation($"Queue messaged added: {message.Message}");
            return message;
        }


        public class QueueMessage
        {
            public string Message { get; set; }
        }
    }
}
