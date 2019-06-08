       <xsd:enumeration value="On" />
            <xsd:enumeration value="Off" />
            <xsd:enumeration value="ClearType" />
          </xsd:restriction>
        </xsd:simpleType>
        <xsd:complexType name="VisualEffectsType">
          <xsd:sequence>
            <xsd:element maxOccurs="1" minOccurs="0" name="FontSmoothing" type="FontSmoothingType" />
          </xsd:sequence>
        </xsd:complexType>
        <xsd:simpleType name="ProtectYourPCType">
          <xsd:restriction base="xsd:integer">
            <xsd:minInclusive value="1" />
            <xsd:maxInclusive value="3" />
          </xsd:restriction>
        </xsd:simpleType>
        <xsd:simpleType name="NetworkLocationType">
          <xsd:restriction base="xsd:string">
            <xsd:enumeration value="Home" />
            <xsd:enumeration value="Work" />
            <xsd:enumeration value="Other" />
          </xsd:restriction>
        </xsd:simpleType>
        <xsd:complexType name="OOBEType">
          <xsd:sequence>
            <xsd:element maxOccurs="1" minOccurs="0" name="SkipMachineOOBE" type="xsd:boolean" wcm:deprecated="SkipMachineOOBE is for testing only. Please see the documentation for important notes." />
            <xsd:element maxOccurs="1" minOccurs="0" name="SkipUserOOBE" type="xsd:boolean" wcm:deprecated="This setting is deprecated and should not be used." />
            <xsd:element maxOccurs="1" minOccurs="0" name="HideEULAPage" type="xsd:boolean" />
            <xsd:element maxOccurs="1" minOccurs="0" name="NetworkLocation" type="NetworkLocationType" />
            <xsd:element maxOccurs="1" minOccurs="0" name="ProtectYourPC" type="ProtectYourPCType" />
            <xsd:element maxOccurs="1" minOccurs="0" name="HideWirelessSetupInOOBE" type="xsd:boolean" />
          </xsd:sequence>
        </xsd:complexType>
        <xsd:simpleType name="GUIDType">
          <xsd:restriction base="xsd:string">
            <xsd:maxLength value="38" />
          </xsd:re