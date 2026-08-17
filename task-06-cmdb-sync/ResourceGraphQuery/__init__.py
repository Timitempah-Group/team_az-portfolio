import azure.functions as func
import json
import logging
from azure.identity import DefaultAzureCredential
from azure.mgmt.resourcegraph import ResourceGraphClient
from azure.mgmt.resourcegraph.models import QueryRequest


def main(mytimer: func.TimerRequest) -> None:
    """Runs daily — queries all Azure resources and outputs a CI inventory."""

    credential = DefaultAzureCredential()
    client = ResourceGraphClient(credential)

    # Query all VMs, VNets, and SQL databases across the subscription
    query = QueryRequest(
        query="""
            Resources
            | where type in (
                'microsoft.compute/virtualmachines',
                'microsoft.network/virtualnetworks',
                'microsoft.sql/servers/databases'
            )
            | project id, name, type, location, resourceGroup,
                       tags, subscriptionId
        """
    )

    result = client.resources(query)

    # Transform to a structured configuration item schema
    ci_inventory = []
    for resource in result.data:
        ci_inventory.append({
            "ci_class": map_type_to_ci_class(resource["type"]),
            "name": resource["name"],
            "azure_resource_id": resource["id"],
            "location": resource["location"],
            "resource_group": resource["resourceGroup"],
            "subscription_id": resource["subscriptionId"],
            "environment": resource.get("tags", {}).get("environment", "unknown"),
            "cost_centre": resource.get("tags", {}).get("cost-centre", "unknown"),
        })

    # In a real integration this would POST to a CMDB system REST API.
    # For this portfolio task, write to a local JSON file.
    with open("/tmp/ci_inventory.json", "w") as f:
        json.dump(ci_inventory, f, indent=2)

    logging.info(f"CI inventory generated: {len(ci_inventory)} records")


def map_type_to_ci_class(azure_type: str) -> str:
    """Maps an Azure resource type to a configuration item class."""
    mapping = {
        "microsoft.compute/virtualmachines": "ci_vm_instance",
        "microsoft.network/virtualnetworks": "ci_network",
        "microsoft.sql/servers/databases": "ci_database",
    }
    return mapping.get(azure_type.lower(), "ci_generic")
