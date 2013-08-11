                                 <xs:complexType>
                                                            <xs:choice minOccurs="0" maxOccurs="unbounded">
                                                                <xs:element name="add" vs:help="configuration/system.serviceModel/services/service/host/baseAddresses/add">
                                                                    <xs:complexType>
                                                                        <xs:attribute name="baseAddress" use="required">
                                                                            <xs:simpleType>
                                                                                <xs:restriction base="xs:string">
                                                                                    <xs:minLength value="1" />
                                                                                    <xs:maxLength value="2147483647" />
                                                                                </xs:restriction>
                                                                            </xs:simpleType>
                                                                        </xs:attribute>
                                                                        <xs:attribute name="lockAttributes" type="xs:string" use="optional" />
                                                                        <xs:attribute name="lockAllAttributesExcept" type="xs:string" use="optional" />
                                                                        <xs:attribute name="lockElements" type="xs:string" use="optional" />
                                                                        <xs:attribute name="lockAllElementsExcept" type="xs:string" use="optional" />
                                                                        <xs:attribute name="lockItem" type="boolean_Type" use="optional" />
                                                                        <xs:anyAttribute namespace="http://schemas.microsoft.com/XML-Document-Transform"
                                                                            processContents="strict"/>
                                                                    </xs:complexType>
                                                                </xs:element>
                                                            </xs:choice>
                                                            <xs:anyAttribute namespace="http://schemas.microsoft.com/XML-Document-Transform"
                                                                processContents="strict"/>
                                                        </xs:complexType>
                                                    </xs:element>
                                                    <xs:element name="timeouts" vs:help="configuration/system.serviceModel/services/service/host/timeouts">
                                                        <xs:complexType>
                                                            <xs:attribute name="closeTimeout" use="optional">
                                                                <xs:simpleType>
                                                                    <xs:restriction base="xs:string">
                                                                        <xs:pattern value="([0-9.]+:){0,1}([0-9]+:){0,1}[0-9.]+" />
                                                                    </xs:restriction>
                                                                </xs:simpleType>
                                                            </xs:attribute>
                                                            <xs:attribute name="openTimeout" use="optional">
                                                                <xs:simpleType>
                                                                    <xs:restriction base="xs:string">
                                                                        <xs:pattern value="([0-9.]+:){0,1}([0-9]+:){0,1}[0-9.]+" />
                                                                    </xs:restriction>
                                                                </xs:simpleType>
                                                            </xs:attribute>
                                                            <xs:attribute name="lockAttributes" type="xs:string" use="optional" />
                                                            <xs:attribute name="lockAllAttributesExcept" type="xs:string" use="optional" />
                                                            <xs:attribute name="lockElements" type="xs:string" use="optional" />
                                                            <xs:attribute name="lockAllElementsExcept" type="xs:string" use="optional" />
                                                            <xs:attribute name="lockItem" type="boolean_Type" use="optional" />
                                                            <xs:anyAttribute namespace="http://schemas.microsoft.com/XML-Document-Transform"
                                                                processContents="strict"/>
                                                        </xs:complexType>
                                                    </xs:element>
                                                </xs:choice>
                                                <xs:attribute name="lockAttributes" type="xs:string" use="optional" />
                                                <xs:attribute name="lockAllAttributesExcept" type="xs:string" use="optional" />
                                                <xs:attribute name="lockElements" type="xs:string" use="optional" />
                                                <xs:attribute name="lockAllElementsExcept" type="xs:string" use="optional" />
                                                <xs:attribute name="lockItem" type="boolean_Type" use="optional" />
                                                <xs:anyAttribute namespace="http://schemas.microsoft.com/XML-Document-Transform" processContents="strict"/>
                                            </xs:complexType>
                                        </xs:element>
                                    </xs:choice>
                                    <xs:attribute name="behaviorConfiguration" use="optional" type="xs:string" />
                                    <xs:attribute name="name" use="required">
                                        <xs:simpleType>
                                            <xs:restriction base="xs:string">
                                                <xs:minLength value="1" />
                                                <xs:maxLength value="2147483647" />
                                            </xs:restriction>
                                        </xs:simpleType>
                                    </xs:attribute>
                                    <xs:attribute name="lockAttributes" type="xs:string" use="optional" />
                                    <xs:attribute name="lockAllAttributesExcept" type="xs:string" use="optional" />
                                    <xs:attribute name="lockElements" type="xs:string" use="optional" />
                                    <xs:attribute name="lockAllElementsExcept" type="xs:string" use="optional" />
                                    <xs:attribute name="lockItem" type="boolean_Type" use="optional" />
                                    <xs:anyAttribute namespace="http://schemas.microsoft.com/XML-Document-Transform" processContents="strict"/>
                                </xs:complexType>
                            </xs:element>
                            <xs:element name="remove" vs:help="configuration/system.serviceModel/services/remove">
                                <xs:complexType>
                                    <xs:attribute