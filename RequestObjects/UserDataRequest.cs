using DevSecOpsApp.Enums;

namespace DevSecOpsApp.RequestObjects
{
    public class UserDataRequest
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public RoleTypeEnum Role { get; set; }
        public int Age {get; set; }
        public string Email { get; set; }
        public string Address { get; set; }

    }
}
