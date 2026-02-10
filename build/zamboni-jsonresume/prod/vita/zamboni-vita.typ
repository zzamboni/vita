// Professional CV generated from JSONResume
// Using brilliant-cv template

#import "@preview/brilliant-cv:3.1.2": *

#let metadata = (
  language: "en",
  name: "Diego Zamboni",
  tagline: "CISO • Organizational Leader • Security Expert • Computer Scientist",

  personal: (
    first_name: "Diego",
    last_name: "Zamboni",
    info: (
      email: "diego@zzamboni.org",
      custom-homepage: (
        awesomeIcon: "home",
        text: "zzamboni.org",
        link: "https://zzamboni.org"
      ),
      location: "Swiss residence permit C",
      linkedin: "zzamboni",
      custom-leanpub: (
        awesomeIcon: "leanpub",
        text: "zzamboni",
        link: "https://leanpub.com/u/zzamboni"
      ),
      github: "zzamboni",
      custom-bluesky: (
        awesomeIcon: "bluesky",
        text: "zzamboni.org",
        link: "https://bsky.app/profile/zzamboni.org"
      )
    )
  ),

  layout: (
    awesome_color: "skyblue",
    before_section_skip: "1pt",
    before_entry_skip: "1pt",
    before_entry_description_skip: "1pt",
    paper_size: "a4",
    page_margin: (x: 1.5cm, y: 1.5cm),

    header: (
      display_profile_photo: true,
      profile_photo_radius_pt: "50%",
      info_row_font_size: "8pt",
      header_align: "center"
    ),

    entry: (
      display_logo: true,
      display_entry_society_first: true,
    ),

    footer: (
      display_page_counter: true,
      display_footer: true,
    ),

    fonts: (),
  ),

  inject: (
    inject_ai_prompt: false,
    inject_keywords: false,
    injected_keywords_list: []
  ),

  lang: (
    en: (
      education: "Education",
      professional: "Professional Experience",
      certificates: "Certifications",
      skills: "Skills",
      projects: "Projects",
      activities: "Professional Activities",
      languages: "Languages",
      date_in_present: "Present",
      cv_footer: [ Curriculum Vitae - #datetime.today().display() ],
      header_quote: "CISO • Organizational Leader • Security Expert • Computer Scientist",
    ),
  ),
)

#let metadata_alt = metadata + (
  layout: metadata.layout + (
    entry: metadata.layout.entry + (
      display_entry_society_first: false,
    )
  )
)

#show: cv.with(
  metadata,
  profile-photo: image("assets/profile/avatar-professional.jpg"),
)

#cv-section("Summary", highlighted: false, letters: 3)

I am a senior computer scientist, computer security expert, IT architect, organization and team leader with 30 years of professional experience, and much longer of being fascinated and passionate about science, computing and education. I specialize in the areas of Computer Security, Cloud Computing, Self-healing Systems and Configuration Management.

I possess a strong combination of leadership, conceptual and technical skills that enable me to help organizations and teams reach their goals. I have excellent communication abilities, with ample experience in writing, teaching and public speaking. I can interact and work fluently at the strategic, tactical and technical levels. I have a Ph.D. in Computer Science and have extensive experience in both academic and business environments.

#cv-section("Professional Highlights", highlighted: false, letters: 3)

#cv-entry(
  metadata: metadata_alt,
  title: [Management and leadership, IT security, cloud computing],
  society: [],
  date: [],
  location: [],
  description: [
    - Chief Information Security Officer for Governance at #link("https://avaloq.com/")[Avaloq], defining and managing Avaloq's global ISO27001-certified Information Security Management System
- Managed security architecture at the #link("https://www.stellantis.com/en/news/press-releases/2022/january/amazon-stellantis-collaborate-on-software-solutions")[Stellantis _Virtual Engineering Workbench_] project. Worked with Stellantis CISO and business stakeholders to define governance, establish security best practices and drive risk analysis, threat modeling and mitigation.
- Established scalable and durable mechanisms to enable partners to work securely in the #link("https://aws.amazon.com/solutions/case-studies/innovators/volkswagen-group/")[Volkswagen Digital Production Platform (DPP)] program.
- Managed security architecture, risk management, data governance and compliance (ISO27001, ISAE3402/3000, etc.) for #link("https://www.swisscom.ch/en/business/enterprise/offer/cloud-data-center.html")[Swisscom's Cloud platforms].
- Established and led the Swisscom IT Clouds security community of practice.
- Established and led the _Health and State Management_ team at Swisscom to design, implement and operate a framework for scalable monitoring, logging and alerting for Swisscom's Cloud platforms.
- Established and led the first computer security organization at UNAM, which has grown into the university's #link("https://www.seguridad.unam.mx/")[Information Security Coordination (UNAM-CERT)].
- Managed IT security customer relationships at HP Enterprise Services, including overseeing the activities of operational and engineering teams, risk and compliance management, requirements discussion and reporting.
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Research, architecture and design],
  society: [],
  date: [],
  location: [],
  description: [
    - Designed the _Orchard_ monitoring framework for Swisscom's _Application Cloud_ platform, and led the team that implemented it and brought it into production.
- Designed and implemented the _Billy Goat_ malware capture and analysis system at IBM.
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Communications and community],
  society: [],
  date: [],
  location: [],
  description: [
    - Author of multiple books including #link("https://cf-learn.info/")[_Learning CFEngine_], #link("https://leanpub.com/learning-hammerspoon")[_Learning Hammerspoon_] and #link("https://leanpub.com/lit-config")[_Literate Configuration_].
- Program chair and program committee member for multiple conferences including the RAID symposium, DIMVA conference, the _Computer Security Day_ and _Computer Security_ conference at UNAM, and others.
- Former member of the Editorial Board of the #link("https://www.sciencedirect.com/journal/computers-and-security")[Computers & Security Journal].
  ]
)

#cv-section("Experience", highlighted: false, letters: 3)

#cv-entry(
  title: [CISO Governance],
  society: [#link("https://avaloq.com/")[Avaloq]],
  date: [Jan 2024 - Present],
  logo: image("assets/logos/Avaloq.jpg"),
  location: [Switzerland],
  description: [
    I lead the global CISO Governance team, focusing on establishing robust security policies and monitoring compliance. I am in charge of defining and monitoring Avaloq's global Information Security Management System. My role involves defining requirements and ensuring effective oversight of first-line security functions, which is essential for maintaining a secure and compliant environment in the financial technology sector.
  ]
)

#cv-entry-start(
  society: [#link("https://aws.amazon.com/")[Amazon Web Services]],
  logo: image("assets/logos/Amazon Web Services.jpg"),
  location: [Switzerland],
)
#v(4pt)

#cv-entry-continued(
  title: [Senior Global Security Architect],
  date: [Oct 2022 - Dec 2023],
  description: [
    I worked with customers and within AWS to increase security awareness, design and build secure solutions, mentor and develop colleagues and customers in security best practices. I was Lead Security Architect in the #link("https://www.stellantis.com/en/news/press-releases/2022/january/amazon-stellantis-collaborate-on-software-solutions")[Stellantis Virtual Engineering Workbench] (VEW) project.
- Established the VEW security workstream to identify customer security requirements and policies, define and promote security best practices and drive activities related to risk analysis, threat modeling and mitigation definition, prioritization and implementation.
- Established in VEW measurement mechanisms for status and metrics for security activities, which provide visibility to both technical and business stakeholders.
- Established the VEW _Security Champions_ program to promote and transfer security knowledge.
- Defined and tracked implementation of security features in VEW to fulfill both customer business requirements and AWS best practices.
  ]
)

#cv-entry-continued(
  title: [Global Security Architect],
  date: [Sep 2021 - Sep 2022],
  description: [
    Worked with AWS global customers to improve security posture and promote secure design and implementation practices. I was a member of the security team in the  #link("https://aws.amazon.com/solutions/case-studies/innovators/volkswagen-group/")[Volkswagen Digital Production Platform (DPP)] project.
- Established in DPP scalable and durable mechanisms to enable DPP partners to work securely in the DPP program.
- Created and promoted security learning materials tailored for various roles within the DPP project.
- Increased security awareness and knowledge by promoting a _Security Guardians_ initiative across the DPP organization.
  ]
)

#cv-entry-start(
  society: [#link("https://swisscom.com/")[Swisscom]],
  logo: image("assets/logos/Swisscom.jpg"),
)
#v(4pt)

#cv-entry-continued(
  title: [Enterprise Architect and IT Clouds Solution Security Architect],
  date: [Apr 2019 - Sep 2021],
  description: [
    As an _Enterprise Architect_, I participated in the design of future products and solutions offered by Swisscom, in collaboration with architects from all other divisions of the company.

As _Solution Security Architect for #link("https://www.swisscom.ch/en/business/enterprise/offer/cloud-data-center.html")[Swisscom's Cloud Platforms]_ (including _Enterprise Service Cloud_, _Enterprise Application Cloud_, _Dynamic Computing Services_, _Enterprise Cloud for SAP Applications_ and related services) I was responsible for the security, compliance and data governance of those services. I  defined, prioritized and drove relevant product features and business goals. I also lead the IT Clouds Security Community of Practice and advised engineering teams on compliance, governance and operational activities.
- Ensured cloud platform and service compliance with internal, contractual and regulatory standards, including ISO27001, ISAE3402/3000 and GDPR.
- Established and led a community of around 30 /Security Champions/ from different teams, who drove security initiatives and promote the security culture within the Swisscom IT Clouds organization.
- Coordinated threat modeling, audits, penetration tests and security compliance reporting.
- Coordinated organization- and team-wide processes for risk and vulnerability management.
- Development of the Swisscom Platforms vision for 2025.
  ]
)

#cv-entry-continued(
  title: [Team Lead & Product Owner for Health & State Management],
  date: [Mar 2016 - Apr 2019],
  description: [
    I built and led a team which evolved on par with Swisscom cloud platforms to provide their monitoring and logging capabilities. My responsibilities included people management (up to 16 people), definition and prioritization of requirements and roadmaps (in collaboration with Product Managers and other stakeholders), technical architecture, and managing the planning and execution of team activities.
- Led the transition of the _Enterprise Cloud_ LEMM (Logging, Event Management and Monitoring) and Access & Inventory frameworks into maintenance mode as the platform was retired.
- Defined the scope and mission of the Health and State Management (HSM) team as part of the new #link("https://www.swisscom.ch/en/business/enterprise/offer/cloud/cloudservices/enterprise-service-cloud.html")[_Enterprise Service Cloud_] project, and later of other platforms as the _IT Clouds_ scope expanded to #link("https://www.swisscom.ch/en/business/enterprise/offer/cloud/cloudservices/application-cloud.html")[_Application Cloud_], #link("https://www.swisscom.ch/en/business/enterprise/offer/platforms-applications/core-business-applications-service/enterprise-cloud-for-sap-solutions.html")[_Enterprise Cloud for SAP Solutions_] and #link("https://www.swisscom.ch/en/business/enterprise/offer/cloud/cloudservices/dynamic-computing-services.html")[_Dynamic Computing Services_].
- Defined the logging and monitoring architecture for the _Enterprise Service Cloud_ platform based on VMware vRealize Operations and vRealize Log Insight.
- Led the transition of the _Application Cloud_ platform monitoring from the Orchard framework to a TICK-based framework.
- Defined architecture and oversaw implementation of the Customer Log Forwarding service.
- Managed business relationship and technical implementation of OpsGenie for alert management in IT Clouds.
- Main technologies involved: VMware vSphere (ESX, vCenter, NSX), VMware vRealize Operations Manager and Log Insight, Ansible (configuration management), OpsGenie (alert management).
  ]
)

#cv-entry-continued(
  title: [Cloud Architect and Orchard Project Lead],
  date: [Aug 2015 - Mar 2016],
  description: [
    Managed a team of three people and led the _Orchard_ project through its implementation, production release and further improvements and development.
  ]
)

#cv-entry-continued(
  title: [Cloud Lab Senior Platform Architect],
  date: [Aug 2014 - Jul 2015],
  description: [
    - Designed the architecture and implemented the initial prototype for the _Orchard_ health-management and self-healing framework for Swisscom's _Application Cloud_ Platform-as-a-Service service.
- Main technologies involved: OpenStack (cloud computing infrastructure), Cloud Foundry (application platform), Consul (health management and service discovery), RabbitMQ (message bus), Riemann (event analysis).
  ]
)

#cv-entry-start(
  society: [#link("https://cfengine.com/")[CFEngine AS]],
  logo: image("assets/logos/CFEngine AS.jpg"),
  location: [Norway/U.S.A. (remote)],
)
#v(4pt)

#cv-entry-continued(
  title: [Product Manager],
  date: [Aug 2013 - Jun 2014],
  description: [
    - Managed the CFEngine language roadmap.
- Created and led the #link("https://docs.cfengine.com/docs/3.10/guide-design-center.html")[CFEngine Design Center] project, which was the foundation for the current #link("https://build.cfengine.com/")[CFEngine Build] service.
- Coordinated the work on CFEngine third-party integration  (e.g. AWS EC2, VMware, Docker and OpenStack).
- Developed code for both the Design Center core and its integrations.
  ]
)

#cv-entry-continued(
  title: [Senior Security Advisor],
  date: [Oct 2011 - Jun 2014],
  description: [
    - CFEngine Advocate, with a special focus on security.
- Wrote the book #link("https://cf-learn.info/")[_Learning CFEngine 3_], published by O'Reilly Media, which became the de facto introductory text to CFEngine.
- Gave talks, wrote articles and blog posts, taught classes, and in general spread the word about CFEngine.
- Developed and implemented the strategy for CFEngine as a security component.
  ]
)

#cv-entry(
  title: [Cofounder, Head of Research and Training],
  society: [Boundless Innovation and Technology],
  date: [Jul 2012 - Jul 2014],
  location: [Mexico],
  description: [
    I advised and coordinated teams working on teaching- and security-related products, consulting and services.
  ]
)

#cv-entry-start(
  society: [#link("https://hp.com/")[HP Enterprise Services]],
  logo: image("assets/logos/HP Enterprise Services.jpg"),
  location: [Mexico],
)
#v(4pt)

#cv-entry-continued(
  title: [Account Security Officer],
  date: [Oct 2010 - Oct 2011],
  description: [
    - Acted as first point of contact for all security-related issues for five HP enterprise customers in Mexico.
- Initiated, advised and managed security-related projects.
- Handled communication and coordination between technical teams involved in security initiatives.
- Involved in all security-related decisions at the sales, design, implementation, delivery and ongoing maintenance stages of IT Outsourcing projects.
  ]
)

#cv-entry-continued(
  title: [IT Outsourcing Service Delivery Consultant],
  date: [Nov 2009 - Oct 2010],
  description: [
    - Helped multidisciplinary customer teams (software engineering, IT management, networking, sales and support) by solving complex problems in customer environments.
- Performed analysis, design and implementation of solutions in multiple areas of expertise, including system automation, configuration management, system administration, system design, virtualization, performance and security.
  ]
)

#cv-entry(
  title: [Research Staff Member],
  society: [#link("https://research.ibm.com/labs/zurich")[IBM Zurich Research Lab]],
  date: [Oct 2001 - Oct 2009],
  logo: image("assets/logos/IBM Zurich Research Lab.jpg"),
  location: [Switzerland],
  description: [
    I was a member of the #link("https://www.zurich.ibm.com/security/")[_Global Security Analysis Laboratory_] (GSAL), where I worked in intrusion detection, malware detection and containment, and virtualization security research projects. See #link("#projects-research")[Research] for details of my research.
  ]
)

#cv-entry(
  title: [Developer (Intern)],
  society: [#link("https://en.wikipedia.org/wiki/Sun_Microsystems")[Sun Microsystems]],
  date: [May 1997 - Aug 1997],
  logo: image("assets/logos/Sun Microsystems.png"),
  location: [U.S.A.],
  description: [
    - Developer for the _Bruce_ host vulnerability scanner, later released as the #link("https://www.usenix.org/legacy/publications/login/1999-11/features/senss.html")[Sun Enterprise Network Security Service] (SENSS).
- Designed and implemented the first version of the network-based components of _Bruce_, which allowed it to operate on several hosts in a network, controlled from a central location.
  ]
)

#cv-entry-start(
  society: [#link("https://www.seguridad.unam.mx/")[National Autonomous University of Mexico (UNAM)]],
  logo: image("assets/logos/National Autonomous University of Mexico (UNAM).jpg"),
  location: [Mexico],
)
#v(4pt)

#cv-entry-continued(
  title: [Founder and lead of Computer Security Area],
  date: [Aug 1995 - Aug 1996],
  description: [
    - Established UNAM's #link("http://www.seguridad.unam.mx/")[_Computer Security Area_], the University's first team dedicated to computer security, which has evolved into the #link("http://www.seguridad.unam.mx/")[_Information Security Coordination (UNAM-CERT)_].
- Managed up to nine people working on different projects related to computer security.
- Managed security monitoring for a Cray supercomputer and 22 Unix workstations.
- Provided security services to the whole University, including incident response, security information, auditing and teaching.
- Established the celebration of the _International Computer Security Day_ (sponsored by the Association for Computing Machinery) at UNAM. Acted as the main organizer of the event for two years (1994 and 1995). This event has grown and evolved into the #link("https://www.disc.unam.mx/")[_Computer Security Day_] and the #link("https://congreso.seguridad.unam.mx/")[_Computer Security Congress_].
- Designed and headed development of an audit-analysis tool for Unix systems (SAINT).
  ]
)

#cv-entry-continued(
  title: [System Administrator],
  date: [Nov 1991 - Aug 1995],
  description: [
    - System administrator at UNAM's Supercomputing Center, managing a #link("http://www.historiadelcomputo.unam.mx/files/fotos/Cray/cray.html")[Cray Y-MP Supercomputer] and related systems.
- Managed the Network Queuing Subsystem (NQS),
- Managed and provided support for 22 Unix workstations.
- Monitored the security of the Cray supercomputer and related workstations.
- Other responsibilities: user administration, operating system installation, resource management, security policies.
  ]
)

#cv-section("Education", highlighted: false, letters: 3)

#cv-entry(
  title: [Ph.D. in Computer Science],
  society: [#link("https://cerias.purdue.edu/")[Purdue University]],
  date: [Aug 1996 - Aug 2001],
  logo: image("assets/logos/Purdue University.jpg"),
  location: [West Lafayette, IN, U.S.A.],
  description: [Thesis: #link("https://zzamboni.org/files/theses/zamboni-phd-thesis.pdf")[Using Internal Sensors for Computer Intrusion Detection]. Advisor: #link("http://spaf.cerias.purdue.edu/")[Eugene H. Spafford]]
)

#cv-entry(
  title: [M.S. in Computer Science],
  society: [#link("https://cerias.purdue.edu/")[Purdue University]],
  date: [Aug 1996 - May 1998],
  logo: image("assets/logos/Purdue University.jpg"),
  location: [West Lafayette, IN, U.S.A.],
  description: [Advisor: #link("http://spaf.cerias.purdue.edu/")[Eugene H. Spafford]]
)

#cv-entry(
  title: [Bachelor's degree in Computer Engineering],
  society: [#link("https://www.unam.mx/")[National Autonomous University of Mexico (UNAM)]],
  date: [Aug 1989 - Jul 1995],
  logo: image("assets/logos/National Autonomous University of Mexico (UNAM).jpg"),
  location: [Mexico City, Mexico],
  description: [Thesis: #link("https://zzamboni.org/files/theses/zamboni-bachelors-thesis.pdf")[UNAM/Cray Project for Security in the Unix Operating System] (in Spanish, original title: _Proyecto UNAM/Cray de Seguridad en el Sistema Operativo Unix_)]
)

#cv-section("Certifications", highlighted: false, letters: 3)

Full list available at #link("https://www.credly.com/users/zzamboni/")[Credly]

#grid(
  columns: (auto, 1fr),
  column-gutter: 1em,
  align: (center + horizon, left + horizon),
  [#image("assets/badges/6430efe4-0ac0-4df6-8f1b-9559d8fcdf27.png", width: 3em)],
  [
    #link("https://www.credly.com/badges/cf7fa455-0305-4aec-a627-bf9ffa133308/public_url")[*AWS Certified Data Analytics – Specialty*], Amazon Web Services Training and Certification (May 2023)
  ]
)

#grid(
  columns: (auto, 1fr),
  column-gutter: 1em,
  align: (center + horizon, left + horizon),
  [#image("assets/badges/6eeb0a98-33cb-4f72-bfc3-f89d65a3286c.png", width: 3em)],
  [
    #link("https://www.credly.com/badges/d74f6e4c-0667-41fb-9243-e11a3793ace4/public_url")[*Certified Information Systems Security Professional (CISSP)*], ISC2 (Apr 2019)
  ]
)

#cv-section("Research", highlighted: false, letters: 3)

_See #link("/vita/publications/")[Publications] for publication details._

#cv-entry(
  metadata: metadata_alt,
  title: [Phantom],
  society: [IBM Research],
  date: [2008 - 2009],
  location: [],
  description: [
    - Developed security solution for VMware virtual environments using virtual machine introspection
- Implemented intrusion detection and prevention capabilities based on VMware VMsafe API
- Publications: #link("/vita/publications/#pub-Christodorescu:2009:CSV:1655008.1655022")[[6]]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://dominoweb.draco.res.ibm.com/d7c39a9a2e73d870852570060051dfed.html")[Billy Goat: Active worm detection and capture]],
  society: [IBM Research],
  date: [2002 - 2008],
  location: [],
  description: [
    - Pioneered active worm-capture technology that became the foundation for modern honeypots and honeynets
- Designed system to simulate thousands of vulnerable hosts to attract and capture propagating worms
- Implemented automated analysis to extract signatures and update intrusion detection/prevention systems
- Publications: #link("/vita/publications/#pub-riordan06:_build_billy_goat:first2006")[[11]], #link("/vita/publications/#pub-riordan05:bg_techreport")[[23]]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("http://www.usenix.org/event/sruti07/tech/full_papers/zamboni/zamboni.pdf")[Router-based Billy Goat]],
  society: [IBM Research],
  date: [2005 - 2007],
  location: [],
  description: [
    - Deployed active worm-capture at network boundary, coupled with border router infrastructure
- Implemented automatic IP address spoofing to cover entire external address space
- Enabled accurate detection of infected local machines and prevention of outbound worm propagation
- Publications: #link("/vita/publications/#pub-zamboni07:sruti07-rbg")[[10]]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [SOC in a Box],
  society: [IBM Research],
  date: [2005 - 2007],
  location: [],
  description: [
    - Pioneered integrated security appliance concept, precursor to modern Unified Threat Management systems
- Combined multiple security functions: intrusion detection, worm detection, vulnerability scanning, and network discovery
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Exorcist],
  society: [IBM Research],
  date: [2001 - 2002],
  location: [],
  description: [
    - Developed host-based intrusion detection system using behavior analysis
- Implemented system call sequence monitoring for anomaly detection
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://zzamboni.org/cerias/zamboni/thesis/")[Ph.D. Thesis: Using internal sensors and embedded detectors for intrusion detection]],
  society: [Purdue University],
  date: [1996 - 2001],
  location: [],
  description: [
    - Investigated novel approaches to data collection for intrusion detection systems
- Implemented and evaluated internal sensors and embedded detectors as data collection mechanisms
- Analyzed trade-offs and effectiveness of different sensor placement strategies in IDS architectures
- Publications: #link("/vita/publications/#pub-zamboni01:phd-thesis")[[27]], #link("/vita/publications/#pub-zamboni02:sensors_detectors")[[12]],  #link("/vita/publications/#pub-kerschbaum00:network-embedded-sensors")[[13]],  #link("/vita/publications/#pub-spafford00:data_collection-techrep")[[25]],  #link("/vita/publications/#pub-zamboni00:thesis-proposal")[[24]], #link("/vita/publications/#pub-zamboni:raid2000")[[32]]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://www.cerias.purdue.edu/site/about/history/coast/projects/aafid.php")[Using autonomous agents for intrusion detection]],
  society: [Purdue University],
  date: [1997 - 1999],
  location: [],
  description: [
    - Designed AAFID architecture for distributed monitoring and intrusion detection using autonomous agents
- Implemented and published prototype as open source, contributing to distributed IDS research community
- Explored novel research approaches in distributed intrusion detection
- Publications: #link("/vita/publications/#pub-spafford00:intrus_detec_auton_agent")[[14]], #link("/vita/publications/#pub-zamboni:aafid-acsac98")[[15]], #link("/vita/publications/#pub-zamboni:aafid-architecture")[[26]], #link("/vita/publications/#pub-zamboni:raid98")[[35]], #link("/vita/publications/#pub-zamboni00:build_aafid_with_perl")[[33]], #link("/vita/publications/#pub-zamboni:raid99")[[34]]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://www.cerias.purdue.edu/site/about/history/coast/projects/coast-proj-synkill.php")[Analysis of a denial-of-service attack on TCP/IP (Synkill)]],
  society: [Purdue University],
  date: [1997],
  location: [],
  description: [
    - Analyzed SYN-flooding denial-of-service attack against TCP/IP protocol
- Developed defense tool to mitigate SYN-flooding attacks
- Publications: #link("/vita/publications/#pub-schuba97:synkill")[[16]], awarded the #link("https://www.cerias.purdue.edu/site/blog/post/a_test_of_time_coast_and_an_award-winning_paper/")[2020 IEEE Security & Privacy Test of Time Award]
  ]
)

#cv-section("Software", highlighted: false, letters: 3)

#cv-entry(
  metadata: metadata_alt,
  title: [Open-source software projects],
  society: [],
  date: [],
  location: [],
  description: [
    - GitHub: #link("https://github.com/zzamboni")[github.com/zzamboni]
- GitLab: #link("https://gitlab.com/zzamboni")[gitlab.com/zzamboni]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Pilatus],
  society: [IBM Research (not publicly available)],
  date: [Jan 2005 - Dec 2007],
  location: [],
  description: [
    An automated system installer that allows arbitrary system installation and configurations, allowing for both proprietary and open source components to be installed in an automated fashion. Open source components can be downloaded directly from their original source to avoid distributing them.
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Embedded Sensors Project],
  society: [Purdue University],
  date: [Jan 1999 - Dec 2001],
  location: [],
  description: [
    A system of sensors for intrusion detection developed in OpenBSD through code instrumentation. Developed as part of my Ph.D. thesis work.
  ]
)

#cv-section("Honors & Awards", highlighted: false, letters: 3)

#cv-honor(
  date: [May 2020],
  title: [IEEE Security & Privacy Test of Time Award (#link("https://www.ieee-security.org/TC/SP2020/awards.html")[IEEE S&P page], #link("https://www.cerias.purdue.edu/site/blog/post/a_test_of_time_coast_and_an_award-winning_paper/")[CERIAS blog post])],
  issuer: [IEEE],
)
#v(6pt)

#cv-honor(
  date: [2010],
  title: [#link("https://cfengine.com/engage/cfengine-champions/")[CFEngine Champion]],
  issuer: [CFEngine AS],
)
#v(6pt)

#cv-honor(
  date: [Jul 2001],
  title: [#link("https://www.cerias.purdue.edu/site/news/view/diego_zamboni_earns_fellowship_from_ibm")[Josef Raviv Memorial Postdoctoral Fellowship]],
  issuer: [IBM],
)
#v(6pt)

#cv-honor(
  date: [Sep 2000],
  title: [UPE Microsoft Scholarship Award],
  issuer: [UPE and Microsoft],
)
#v(6pt)

#cv-honor(
  date: [Apr 1998],
  title: [#link("http://upe.acm.org/")[Member of Upsilon Pi Epsilon]],
  issuer: [Association for Computing Machinery (ACM)],
)
#v(6pt)

#cv-honor(
  date: [Apr 2001],
  title: [Member of Phi Beta Delta],
  issuer: [Phi Beta Delta honor society],
)
#v(6pt)

#cv-honor(
  date: [May 1996],
  title: [Fulbright Scholarship (for pursuing Ph.D. studies at Purdue University)],
  issuer: [Fulbright Program and CONACYT],
)
#v(6pt)

#cv-section("Program Committees and Boards", highlighted: false, letters: 3)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://www.sciencedirect.com/journal/computers-and-security")[Editorial Board Member]],
  society: [Computers & Security Journal, Elsevier],
  date: [2011 - 2013],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://dblp.org/db/conf/raid/index.html")[Program Committee (2001-2005), Program Chair (2006), Steering Committee (2007-2017)]],
  society: [Intl. Symposium on Recent Advances in Intrusion Detection (RAID)],
  date: [2001 - 2017],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Program co-chair],
  society: [IBM Academy of Technology Security and Privacy Symposium (internal IBM event)],
  date: [Jun 2009],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://www.video.ethz.ch/conferences/2009/zisc.html")[Program Chair]],
  society: [#link("https://zisc.ethz.ch/")[ZISC] Workshop on Security in Virtualized Environments and Cloud Computing],
  date: [Sep 2009],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://www.dimva.org/dimva2008/")[Program Chair]],
  society: [Detection of Intrusions and Malware & Vulnerability Assessment (DIMVA)],
  date: [Jul 2008],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("http://www.ieee-security.org/TC/SP-Index.html")[Program Committee Member]],
  society: [IEEE Security and Privacy Symposium],
  date: [May 2007],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("http://www.acsac.org/")[Program Committee Member]],
  society: [Annual Computer Security Applications Conference (ACSAC)],
  date: [2003 - 2007],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [#link("https://www.disc.unam.mx/")[Founder and Program Committee Member]],
  society: [Computer Security Day Conference],
  date: [1994 - 2000],
  location: [],
  description: [
    
  ]
)

#cv-section("Student Advising", highlighted: false, letters: 3)

#cv-entry(
  metadata: metadata_alt,
  title: [Urko Zurutuza Ortega (Mondragon University, Spain)],
  society: [IBM Research],
  date: [Jan 2005 - Dec 2008],
  location: [],
  description: [
    - Ph.D. co-advisor
- Thesis: #link("https://dialnet.unirioja.es/servlet/tesis?codigo=20012")[Data Mining Approaches for Analysis of Worm Activity Towards Automatic Signature Generation]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Milton Yates (ENST Bretagne, France)],
  society: [IBM Research],
  date: [Jan 2005 - Dec 2005],
  location: [],
  description: [
    - External Diploma Thesis advisor
- Thesis: #link("https://www.usenix.org/conference/sruti-07/boundary-detection-and-containment-local-worm-infections")[The Router-based Billy Goat Project]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Candid Wüest (ETH Zurich, Switzerland)],
  society: [IBM Research],
  date: [Jan 2002 - Dec 2003],
  location: [],
  description: [
    - Diploma Thesis advisor
- Thesis: #link("https://pub.tik.ee.ethz.ch/students/2002-2003-Wi/DA-2003-22.pdf")[Desktop Firewalls and Intrusion Detection]
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Daniele Sgandurra (University of Pisa, Italy)],
  society: [IBM Research],
  date: [Jan 2009 - Dec 2009],
  location: [],
  description: [
    - Internship advisor
- Project: Design and implementation of process injection using virtual machine introspection.
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Martin Carbone (Georgia Institute of Technology, U.S.A.)],
  society: [IBM Research],
  date: [Jan 2007 - Dec 2007],
  location: [],
  description: [
    - Internship advisor
- Project: Implementation of a proof of concept Hyperjacking attack on Intel platform.
  ]
)

#cv-section("Teaching", highlighted: false, letters: 3)

#cv-entry(
  metadata: metadata_alt,
  title: [CISSP training (30 hours)],
  society: [iNetworks, Mexico (remote class)],
  date: [2020],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [CFEngine one-day training class (8 hours)],
  society: [Multiple venues],
  date: [2011 - 2013],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Virtualization lecture (2 hours), Systems Security class, Computer Science Dept.],
  society: [ETH Zürich],
  date: [2011 - 2013],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Intrusion detection: Basic concepts and current research at IBM class (3 hours), Information Technology Security Spring School],
  society: [University of Lausanne],
  date: [2005],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Introduction to Computer Security class (40 hours)],
  society: [ITESM, Mexico],
  date: [2003],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [EE495 (Information Extraction, Retrieval and Security) course],
  society: [Purdue University, U.S.A.],
  date: [2000],
  location: [],
  description: [
    - Co-designed eight security-related lectures and taught two of them
- Co-designed the class project
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [SSH: Achieving secure communication over insecure channels class],
  society: [CSI NetSec conference, U.S.A.],
  date: [2000],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Protecting your computing system class],
  society: [Schlumberger, U.S.A.],
  date: [1997],
  location: [],
  description: [
    
  ]
)

#cv-entry(
  metadata: metadata_alt,
  title: [Supercomputing Internship Program Courses],
  society: [UNAM, Mexico],
  date: [1991 - 1996],
  location: [],
  description: [
    Designed and taught multiple courses (10-40 hours long) on the following topics:
- Introduction to Unix
- Unix utilities
- Unix security
- Basic Unix administration
- Advanced Unix administration
- UNICOS system administration on Cray supercomputers
  ]
)

#cv-section("Other Professional Activities", highlighted: false, letters: 3)

#cv-entry(
  title: [Member],
  society: [#link("http://www.acm.org/")[The Association for Computing Machinery (ACM)]],
  date: [1998 - Present],
  location: [],
  description: []
)

#cv-entry(
  title: [Founder],
  society: [#link("http://purdue.pm.org/")[Purdue.pm, the Purdue Perl Users Group]],
  date: [2000],
  location: [],
  description: []
)

#cv-entry(
  title: [Secretary and President],
  society: [#link("https://www.cs.purdue.edu/future-students/organizations.html")[Purdue University Chapter of Upsilon Pi Epsilon]],
  date: [1998 - 2000],
  location: [],
  description: []
)

#cv-section("Publications", highlighted: false, letters: 3)

#cv-entry(
  title: [#link("/vita/publications/")[Full list online]],
  society: [],
  date: [],
  location: [],
  description: []
)

#cv-section("Skills", highlighted: false, letters: 3)

#cv-skill(type: [Leadership], info: [32 years of multidisciplinary team and project leadership experience #sym.dot.c IT Enterprise Architecture #sym.dot.c Scaled Agile Framework (SAFe)])
#v(6pt)

#cv-skill(type: [Communication], info: [Excellent written and spoken communication skills #sym.dot.c Extensive public speaking experience #sym.dot.c Professional writing and teaching experience])
#v(6pt)

#cv-skill(type: [Information and Cyber Security], info: [Enterprise security governance #sym.dot.c Enterprise security architecture #sym.dot.c Virtualization and cloud computing security #sym.dot.c Risk management and compliance #sym.dot.c Intrusion detection and prevention #sym.dot.c Software security and secure software development #sym.dot.c ISO27001])
#v(6pt)

#cv-skill(type: [Technology], info: [Broad and deep IT expertise #sym.dot.c Cloud computing #sym.dot.c Computer security #sym.dot.c Operating systems #sym.dot.c Networking #sym.dot.c Configuration management #sym.dot.c Software & services development #sym.dot.c Programming languages])
#v(6pt)

#cv-skill(type: [Cloud Computing], info: [AWS architecture #sym.dot.c AWS security #sym.dot.c AWS infrastructure and development #sym.dot.c Held multiple AWS Professional- and Associate-level certifications (Security, Solutions Architect, Dev/Sysops) from 2022-2025])
#v(6pt)

#cv-skill(type: [Research], info: [Ph.D. in Computer Science #sym.dot.c 9 years of experience at IBM Research])
#v(6pt)

#cv-skill(type: [Programming Languages], info: [Ruby #sym.dot.c Python #sym.dot.c C #sym.dot.c Perl #sym.dot.c Java #sym.dot.c LISP family (Clojure, Racket) #sym.dot.c Unix shells and tools])
#v(6pt)

#cv-skill(type: [Systems & Development], info: [Unix/Linux systems engineering and administration #sym.dot.c System health management and monitoring #sym.dot.c Cloud platforms #sym.dot.c Software development #sym.dot.c Configuration management (CFEngine, Puppet, Chef, Ansible)])
#v(6pt)

#cv-skill(type: [Development Environments & Technologies], info: [Unix/Linux #sym.dot.c Cloud Foundry #sym.dot.c Amazon EC2 #sym.dot.c macOS #sym.dot.c VMware (ESX, vSphere) #sym.dot.c OpenStack #sym.dot.c Docker #sym.dot.c REST APIs #sym.dot.c XML and related technologies #sym.dot.c Network programming #sym.dot.c Database programming (SQL) #sym.dot.c Kernel programming (OpenBSD and Linux) #sym.dot.c HTML])
#v(6pt)

#cv-section("Languages", highlighted: false, letters: 3)

#cv-skill(type: [Spanish], info: [Native])

#cv-skill(type: [English], info: [Full proficiency])

#cv-skill(type: [German], info: [Intermediate proficiency (B2 level)])

#cv-section("References", highlighted: false, letters: 3)

- Available by request

