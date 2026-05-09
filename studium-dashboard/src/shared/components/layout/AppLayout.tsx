import { Layout, Menu } from 'antd';
import { Outlet, useNavigate } from 'react-router-dom';
import {
  TeamOutlined, BookOutlined, FileTextOutlined,
  MessageOutlined, BarChartOutlined, SettingOutlined
} from '@ant-design/icons';

const { Sider, Content } = Layout;

const menuItems = [
  { key: '/students',     icon: <TeamOutlined />,     label: 'Étudiants' },
  { key: '/programs',     icon: <BookOutlined />,     label: 'Programmes' },
  { key: '/applications', icon: <FileTextOutlined />, label: 'Candidatures' },
  { key: '/messaging',    icon: <MessageOutlined />,  label: 'Messagerie' },
  { key: '/reporting',    icon: <BarChartOutlined />, label: 'Reporting' },
  { key: '/settings',     icon: <SettingOutlined />,  label: 'Paramètres' },
];

export default function AppLayout() {
  const navigate = useNavigate();
  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider>
        <div style={{ padding: 16, color: 'white', fontWeight: 'bold' }}>
          Studium
        </div>
        <Menu
          theme="dark"
          mode="inline"
          items={menuItems}
          onClick={({ key }) => navigate(key)}
        />
      </Sider>
      <Content style={{ padding: 24 }}>
        <Outlet />
      </Content>
    </Layout>
  );
}